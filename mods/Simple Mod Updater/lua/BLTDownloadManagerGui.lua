local smu_original_bltdownloadmanager_startdownload = BLTDownloadManager.start_download
function BLTDownloadManager:start_download( update )
	local download = update.postponed_download
	if download then
		table.insert( self._downloads, download )
		self:clbk_download_finished( download.data, download.http_id )
		return true
	end

	return smu_original_bltdownloadmanager_startdownload( self, update )
end

-- remove when https://gitlab.com/znixian/payday2-superblt-lua/-/commit/829c6d52320410d975c30a6b99673b882f660cfb finally hits production
function BLTDownloadManager:clbk_download_finished( data, http_id )
	local download = self:get_download_from_http_id( http_id )
	log(string.format("[Downloads] Finished download of %s (%s)", download.update:GetName(), download.update:GetParentMod():GetName()))

	-- Holy shit this is hacky, but to make sure we can update the UI correctly to reflect whats going on, we run this in a coroutine
	-- that we start through a UI animation
	self._coroutine_ws = self._coroutine_ws or managers.gui_data:create_fullscreen_workspace()
	download.coroutine = self._coroutine_ws:panel():panel({})

	local save = function()

		-- Create locals
		local wait = function( x )
			for i = 1, (x or 5) do
				coroutine.yield()
			end
		end

		local install_dir = download.update:GetInstallDirectory()
		local temp_dir = Application:nice_path( install_dir .. "_temp" )
		if install_dir == BLTModManager.Constants:ModsDirectory() then
			temp_dir = Application:nice_path( BLTModManager.Constants:DownloadsDirectory() .. "_temp" )
		end

		local file_path = Application:nice_path( BLTModManager.Constants:DownloadsDirectory() .. tostring(download.update:GetId()) .. ".zip" )
		local temp_install_dir = Application:nice_path( temp_dir .. "/" .. download.update:GetInstallFolder() )
		local install_path = Application:nice_path( download.update:GetInstallDirectory() .. download.update:GetInstallFolder() )
		local extract_path = Application:nice_path( temp_install_dir .. "/" .. download.update:GetInstallFolder() )

		local cleanup = function()
			SystemFS:delete_file( temp_install_dir )
		end

		wait()

		-- Prepare
		SystemFS:make_dir( temp_dir ) -- we dont wanna delete the temp dir at all, as it would not be thread safe. just make sure it exists.
		SystemFS:delete_file( file_path )
		cleanup()

		-- Save download to disk
		log("[Downloads] Saving to downloads...")
		download.state = "saving"
		wait()

		-- Save file to downloads
		local f = io.open( file_path, "wb+" )
		if f then
			f:write( data )
			f:close()
		end

		-- Start download extraction
		log("[Downloads] Extracting...")
		download.state = "extracting"
		wait()

		unzip( file_path, temp_install_dir )

		-- Update extract_path, in case user renamed mod's folder
		local folders = SystemFS:list(temp_install_dir, true)
		local extracted_folder_name = folders and #folders == 1 and folders[1]
		if extracted_folder_name and extracted_folder_name ~= download.update:GetInstallFolder() then
			extract_path = Application:nice_path( temp_install_dir .. "/" .. extracted_folder_name )
		end

		-- Verify content hash with the server hash
		log("[Downloads] Verifying...")
		download.state = "verifying"
		wait()

		local passed_check = false
		if download.update:UsesHash() then
			local local_hash = file.DirectoryHash( Application:nice_path( extract_path, true ) )
			local server_hash = download.update:GetServerHash()
			if server_hash == local_hash then
				passed_check = true
			else
				log("[Downloads] Failed to verify hashes!")
				log("[Downloads] Server: ", server_hash)
				log("[Downloads]  Local: ", local_hash)
			end
		else
			local mod_txt = extract_path.."/mod.txt" -- Check the downloaded mod.txt (if it exists) to know we are downloading a valid mod with valid version.
			if SystemFS:exists(mod_txt) then
				local file = io.open(mod_txt, 'r')
				local mod_data = json.decode(file:read("*all"))
				if mod_data then -- Is the data valid json?
					local version = mod_data.version
					local server_version = download.update:GetServerVersion()
					if server_version == version then
						passed_check = true
					else -- Versions don't match
						log("[Downloads] Failed to verify versions!")
						log("[Downloads] Server: ", server_version)
						log("[Downloads]  Local: ", version)
					end
				else
					log("[Downloads] Could not read mod data of downloaded mod!")
				end
				file:close()
			else
				log("[Downloads] Downloaded mod is not a valid mod!")
			end
		end
		if not passed_check then
			download.state = "failed"
			cleanup()
			return
		end

		-- Remove old installation, unless we're installing a mod (via dependencies)
		if not download.update:IsInstall() then
			wait()
			if SystemFS:exists(install_path) then
				local old_install_path = install_path .. '_old'
				log("[Downloads] Removing old installation...")
				if not file.MoveDirectory( install_path, old_install_path ) then
					log("[Downloads] Failed to rename old installation!")
					download.state = "failed"
					cleanup()
					return
				end

				if not SystemFS:delete_file( old_install_path ) then
					log("[Downloads] Failed to delete old installation!")
					download.state = "failed"
					cleanup()
					return
				end
			end
		end

		-- Move the temporary installation
		local move_success = file.MoveDirectory( extract_path, install_path )
		if not move_success then
			log("[Downloads] Failed to move installation directory!")
			download.state = "failed"
			cleanup()
			return
		end

		-- Mark download as complete
		log("[Downloads] Complete!")
		download.state = "complete"
		cleanup()

	end

	download.coroutine:animate( save )
end

local smu_original_bltdownloadmanager_clbkdownloadfinished = BLTDownloadManager.clbk_download_finished
function BLTDownloadManager:clbk_download_finished( data, http_id, ... )
	local download = self:get_download_from_http_id( http_id )
	if not download then
		return
	elseif type( data ) == 'string' and data:sub( 1, 2 ) == 'PK' then
		local update = download.update
		if update and update.is_simple then
			if SimpleModUpdater.settings.auto_install then
				update.notification_id = BLT.Notifications:add_notification( {
					title = update:GetParentMod():GetName(),
					text = managers.localization:text( 'smu_autoinstall_mod_update' ),
					priority = 1001,
				} )
			end
			if SimpleModUpdater.settings.auto_install or update.postponed_download then
				local file_path = Application:nice_path( BLTModManager.Constants:DownloadsDirectory() .. tostring(update:GetId()) .. '.zip' )
				SimpleModUpdater.my_zips[ file_path ] = update
				update.postponed_download = nil
			else
				download.data = data
				download.state = 'already_downloaded'
				update.postponed_download = download
				for i, dl in ipairs( self._downloads ) do
					if download == dl then
						table.remove( self._downloads, i )
						break
					end
				end
				BLT.Downloads:add_pending_download( update )
				return
			end
		end
	else
		download.state = 'failed'
		return
	end

	smu_original_bltdownloadmanager_clbkdownloadfinished( self, data, http_id, ... )
end

local smu_bltdownloadmanagergui_setup = BLTDownloadManagerGui.setup
function BLTDownloadManagerGui:setup()
	smu_bltdownloadmanagergui_setup(self)

	if next(BLT.Downloads:pending_downloads()) then
		local padding = self._buttons[2]._panel:top() - self._buttons[1]._panel:bottom()
		local uall_panel = self._buttons[#self._buttons]._panel

		local button = BLTUIButton:new( self._scroll:canvas(), {
			x = uall_panel:x() - uall_panel:w() - padding,
			y = uall_panel:y(),
			w = uall_panel:w(),
			h = uall_panel:h(),
			text = managers.localization:text('menu_restart_game'),
			center_text = true,
			callback = callback( self, self, 'smu_clbk_restart' )
		} )
		table.insert( self._buttons, button )
	end
end

function BLTDownloadManagerGui:smu_clbk_restart()
	setup:load_start_menu()
end

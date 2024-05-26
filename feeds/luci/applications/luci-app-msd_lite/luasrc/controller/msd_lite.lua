module("luci.controller.msd_lite", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/msd_lite") then
		return
	end

	local page = entry({"admin", "services", "msd_lite"}, cbi("msd_lite"), _("msd_lite"))
	page.dependent = true

	entry({"admin", "services", "msd_lite", "status"}, call("status")).leaf = true
	entry({"admin", "services", "msd_lite", "act_status"}, call("act_status")).leaf = true
end

function status()
	local e = {}
	e.running = luci.sys.call("pgrep msd_lite >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function act_status()
	local uci = luci.model.uci.cursor()
	local port = uci:get("msd_lite", "config", "port")
	local ipt = io.popen("lsof -i -n|grep ".. port .."|grep ESTABLISHED|awk {'print $9'} 2>/dev/null")
	if ipt then
		local fwd = { }
		while true do
			local ln = ipt:read("*l")
			if not ln then
				break
			else
				local client = ln
						fwd[#fwd+1] = {
						client = client
					}
			end
		end
		ipt:close()

		luci.http.prepare_content("application/json")
		luci.http.write_json(fwd)
	end
end
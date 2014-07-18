Facter.add("raidcontroller") do
	confine :kernel => :linux

	setcode do
		controllers = Array.new

		if File.executable?("/usr/bin/lspci")
			output = %x{/usr/bin/lspci}
			output.split(/\n/).each do |line|
				controllers.push("sas2ircu") if line =~ /SAS2008/
				controllers.push("megaraid") if line =~ /(MegaRAID SAS 1078|MegaSAS 9260|MegaRAID SAS 9240|MegaRAID SAS 2208|MegaRAID SAS 2008|MegaRAID SAS 2108)/
				controllers.push("3ware") if line =~ /3ware Inc 9690SA/
				controllers.push("aac-raid") if line =~ /Adaptec AAC-RAID/
				controllers.push("cciss") if line =~ /Hewlett-Packard Company Smart Array G6 controllers/
				controllers.push("areca") if line =~ /ARC-1210/
			end
		end

		if File.readable?("/proc/mpt/ioc0/info")
			File.open("/proc/mpt/ioc0/info").each do |line|
				if line =~ /LSISAS1068E/ or line =~/LSISAS1064E/ or line =~ /Symbios Logic SAS1064ET/
					if File.executable?('/usr/sbin/mpt-status')
						output=%x{/usr/sbin/mpt-status}
							controllers.push("sas1068") if output =~ /ioc0/m
					end
				end
			end
		end

		if File.readable?("/proc/mdstat")
			mdstat = File.read("/proc/mdstat")
			controllers.push("linux_software_raid") if mdstat =~ /^md/mi
		end

		if File.exists?('/dev/cciss/c0d0')
			controllers.push("cciss")
		end

		controllers.uniq.join(",") if controllers.count > 0
	end
end

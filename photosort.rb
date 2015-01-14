#!c:\Ruby193\bin\ruby.exe

require 'logger'
require 'time'
require 'fileutils'

# set up the logger and other vars
$log = Logger.new("photosort.log", 1, 1024000)
$log.level = Logger::DEBUG
$deletefolder = true  # set this to true if relevant folders should be removed (if empty) after processing
$months = {"01" => "Jan", "02" => "Feb", "03" => "Mar", "04" => "Apr", "05" => "May", "06" => "Jun",
         "07" => "Jul", "08" => "Aug", "09" => "Sep", "10" => "Oct", "11" => "Nov", "12" => "Dec"}

# methods =======================
def createfolder (folderpath)
    unless Dir.exist?(folderpath) 
    	$log.debug("create folder: #{folderpath}")
        begin
        	Dir.mkdir(folderpath, 0755)
        rescue SystemCallError
        	$log.debug("cannot create the folder: #{targetyearfolderpath}" + $!)
        	return false
        end
    end
    return true
end

def getFileCopyName(path, filename)
    noname = true
    origname = filename
    filepath = ""
    filecount = 1
    while noname do
    	filepath = path + "/" + filename
    	$log.debug("Check #{filepath}")
    	#check for existence of file
    	if File.exists?(filepath)
    		$log.debug("file exists #{filepath}")
    		filename = origname.sub(/\./,"_#{filecount}.")
    		filecount += 1
    	else
    		# we have a valid name!
    		noname = false
    	end
    end
    return filepath
end

def processfolder (folder)
	$log.debug("processfolder for #{folder}")
	return if folder == "."
	return if folder == ".."
	if /\-/.match(folder) || /\_/.match(folder)
		print "  Should I process folder #{folder} (y/n)? "
        uinput = gets.chomp
        if uinput =="y"
        	puts " sorting #{folder}"
        	sortfolder(folder)
        else
        	puts " skipping #{folder}"
        end
	end
end

def sortfolder (folder)
	startdir = Dir.getwd
	sortdir = startdir + "/#{folder}"
	$log.debug("sortfolder for #{sortdir}")
	Dir.chdir(sortdir)
	files = []
	files = Dir.entries(sortdir).select {|entry| File.file?(entry)}

    # move file to target dir based on date it was taken
    files.each do |file|
        timeelements = []
        timeelements = File.mtime(file).to_s.split(" ")
        dateelements = []
        dateelements = timeelements[0].split("-")
        # need to create target folder for this file (2nd element of dateelements array)
        targetyearfolderpath = startdir + "/#{dateelements[0]}"
        unless createfolder(targetyearfolderpath) 
        	puts ("exiting - cannot create the folder: #{targetyearfolderpath}")
        	exit
        end
        targetfolder = dateelements[0] + "/" + $months[dateelements[1]]
        targetfolderpath = startdir + "/#{targetfolder}" 
        unless createfolder(targetfolderpath) 
        	puts ("exiting - cannot create the folder: #{targetfolderpath}")
        	exit
        end
        filename = getFileCopyName(targetfolderpath, file)
        puts("  move #{file} to #{filename}")
        currfile = sortdir + "/" + file
        $log.debug("  move #{currfile} to #{filename}")
        FileUtils.mv currfile, filename
    end
    Dir.chdir(startdir)
    # remove the directory if it is now empty
    begin
        Dir.delete(sortdir)
    rescue SystemCallError
    	puts "  #{folder} is not empty - will leave it behind"
    end
end

# Main routine =================== 
$log.info("==============#{Time.now}===============")

# prompt the user to determine which folder we should be sorting
homedir = Dir.getwd
$log.debug("homedir = #{homedir}")

puts "Hi Amy - welcome to the new and improved photosort"
print "Do you want me to scan folders in #{homedir} (y/n)? "
uinput = gets.chomp
if uinput == "n"
    ans=false
	while !ans
	    print "Which user's pictures would you like me to scan (or type 'exit')? "
	    uuser = gets.chomp
	    exit if uuser.downcase == "exit"
	    homedir = "c:/Users/#{uuser}/Pictures"
	    ans=File.directory?(homedir)
	    puts "   Hmm... I cannot find #{homedir} - you sure about that?" unless ans
	end
elsif uinput != "y"
	puts "y or n for that question..."
	exit
end

$log.debug("Scanning #{homedir}")
puts "Scanning #{homedir}"

# head to the designated directory and get the file/folder listings
Dir.chdir(homedir)

folders = []
folders = Dir.entries(homedir).select {|entry| File.directory?(entry)}

$log.debug("folders found: #{folders}")

# for each folder, determine if it is one we want to process (i.e. the folder name is one of the targeted formats)

folders.each { |n| processfolder(n) }

# wrap it up with the caller
print "OK, we're done.  Press any key to exit!"
anykey = gets.chomp
exit
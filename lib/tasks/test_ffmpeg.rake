namespace :ffmpeg do
  desc "Test FFmpeg availability"
  task test: :environment do
    puts "Testing FFmpeg availability..."
    
    # Test 1: Check if ffmpeg command exists
    ffmpeg_available = system('which ffmpeg > /dev/null 2>&1')
    puts "FFmpeg command available: #{ffmpeg_available}"
    
    if ffmpeg_available
      # Test 2: Check FFmpeg version
      version_output = `ffmpeg -version 2>/dev/null | head -1`
      puts "FFmpeg version: #{version_output.strip}"
      
      # Test 3: Check libmp3lame codec availability
      codecs_output = `ffmpeg -codecs 2>/dev/null | grep mp3`
      puts "MP3 codec support:"
      puts codecs_output
    else
      puts "FFmpeg is not available - audio conversion will fail"
      puts "Checking system packages..."
      system('which apt-get > /dev/null 2>&1 && dpkg -l | grep ffmpeg || echo "apt-get not available"')
      system('which apk > /dev/null 2>&1 && apk list | grep ffmpeg || echo "apk not available"')
      system('which nix-env > /dev/null 2>&1 && nix-env -q | grep ffmpeg || echo "nix not available"')
    end
  end
end
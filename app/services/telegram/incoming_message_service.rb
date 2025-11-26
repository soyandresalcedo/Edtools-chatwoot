# Find the various telegram payload samples here: https://core.telegram.org/bots/webhooks#testing-your-bot-with-updates
# https://core.telegram.org/bots/api#available-types

class Telegram::IncomingMessageService
  include ::FileTypeHelper
  include ::Telegram::ParamHelpers
  pattr_initialize [:inbox!, :params!]

  def perform
    # chatwoot doesn't support group conversations at the moment
    transform_business_message!
    return unless private_message?

    set_contact
    update_contact_avatar
    set_conversation
    # TODO: Since the recent Telegram Business update, we need to explicitly mark messages as read using an additional request.
    # Otherwise, the client will see their messages as unread.
    # Chatwoot defines a 'read' status in its enum but does not currently update this status for Telegram conversations.
    # We have two options:
    # 1. Send the read request to Telegram here, immediately when the message is created.
    # 2. Properly update the read status in the Chatwoot UI and trigger the Telegram request when the agent actually reads the message.
    # See: https://core.telegram.org/bots/api#readbusinessmessage
    @message = @conversation.messages.build(
      content: telegram_params_message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      sender: message_sender,
      content_attributes: telegram_params_content_attributes,
      source_id: telegram_params_message_id.to_s
    )

    process_message_attachments if message_params?
    @message.save!
  end

  private

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: telegram_params_from_id,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    # TODO: Should we update contact_attributes when the user changes their first or last name?
    # In business chats, when our Telegram bot initiates the conversation,
    # the message does not include a language code.
    # This is critical for AI assistants and translation plugins.

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def process_message_attachments
    attach_location
    attach_files
    attach_contact
  end

  def update_contact_avatar
    return if @contact.avatar.attached?

    avatar_url = inbox.channel.get_telegram_profile_image(telegram_params_from_id)
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, avatar_url) if avatar_url
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: conversation_additional_attributes
    }
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations
                                    .where.not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: "#{telegram_params_first_name} #{telegram_params_last_name}",
      additional_attributes: additional_attributes
    }
  end

  def additional_attributes
    {
      # TODO: Remove this once we show the social_telegram_user_name in the UI instead of the username
      username: telegram_params_username,
      language_code: telegram_params_language_code,
      social_telegram_user_id: telegram_params_from_id,
      social_telegram_user_name: telegram_params_username
    }
  end

  def conversation_additional_attributes
    {
      chat_id: telegram_params_chat_id,
      business_connection_id: telegram_params_business_connection_id
    }
  end

  def message_type
    business_message_outgoing? ? :outgoing : :incoming
  end

  def message_sender
    business_message_outgoing? ? nil : @contact
  end

  def file_content_type
    return :image if image_message?
    return :audio if audio_message?
    return :video if video_message?

    file_type(params[:message][:document][:mime_type])
  end

  def image_message?
    params[:message][:photo].present? || params.dig(:message, :sticker, :thumb).present?
  end

  def audio_message?
    params[:message][:voice].present? || params[:message][:audio].present?
  end

  def video_message?
    params[:message][:video].present? || params[:message][:video_note].present?
  end

  def attach_files
    return unless file

    file_id = file.is_a?(Hash) ? file[:file_id] : file['file_id']
    file_download_path = inbox.channel.get_telegram_file_path(file_id)
    if file_download_path.blank?
      Rails.logger.info "Telegram file download path is blank for #{file_id} : inbox_id: #{inbox.id}"
      return
    end

    attachment_file = Down.download(file_download_path)

    if audio_message?
      attach_audio_file(attachment_file)
    else
      attach_regular_file(attachment_file)
    end
  end

  def attach_audio_file(oga_file)
    Rails.logger.info "Starting audio file processing for message #{@message&.id}"
    Rails.logger.info "Original filename: #{oga_file.original_filename}"
    Rails.logger.info "Content type: #{oga_file.content_type}"

    ffmpeg_check = ffmpeg_available?
    Rails.logger.info "FFmpeg available: #{ffmpeg_check}"

    if ffmpeg_check
      Rails.logger.info 'Attempting OGA to MP3 conversion...'
      mp3_file = convert_oga_to_mp3(oga_file)
      create_attachment(mp3_file, 'audio/mpeg', 'audio.mp3')
      Rails.logger.info "Successfully converted OGA to MP3 for message #{@message.id}"
    else
      Rails.logger.warn 'FFmpeg not available, using original OGA format'
      # Check what's actually available
      system_info = `which ffmpeg 2>/dev/null || echo "ffmpeg not found"`
      Rails.logger.warn "System check: #{system_info.strip}"
      create_attachment(oga_file, oga_file.content_type, oga_file.original_filename)
    end
  rescue StandardError => e
    Rails.logger.error "Audio conversion failed: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(3).join(', ')}"
    Rails.logger.error 'Using original OGA format as fallback'
    create_attachment(oga_file, oga_file.content_type, oga_file.original_filename)
  end

  def attach_regular_file(attachment_file)
    create_attachment(attachment_file, attachment_file.content_type, attachment_file.original_filename)
  end

  def create_attachment(file_io, content_type, filename)
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type,
      file: {
        io: file_io,
        filename: filename,
        content_type: content_type
      }
    )
  end

  def ffmpeg_available?
    return @ffmpeg_available if defined?(@ffmpeg_available)

    # Test multiple ways to detect ffmpeg
    which_test = system('which ffmpeg > /dev/null 2>&1')
    command_test = system('ffmpeg -version > /dev/null 2>&1')

    Rails.logger.info "FFmpeg detection - which: #{which_test}, command: #{command_test}"

    # Try to get more info about the system
    unless which_test
      Rails.logger.warn 'FFmpeg not found in PATH'
      # Check common locations
      ['/usr/bin/ffmpeg', '/usr/local/bin/ffmpeg', '/nix/store/*/bin/ffmpeg'].each do |path|
        next unless File.exist?(path) || Dir.glob(path).any?

        Rails.logger.info "Found FFmpeg at: #{path}"
        @ffmpeg_available = true
        return @ffmpeg_available
      end
    end

    @ffmpeg_available = which_test && command_test
  end

  def convert_oga_to_mp3(oga_file)
    temp_dir = Rails.root.join('tmp/audio_conversion')
    FileUtils.mkdir_p(temp_dir)

    input_path = File.join(temp_dir, "input_#{SecureRandom.hex(8)}.oga")
    output_path = File.join(temp_dir, "output_#{SecureRandom.hex(8)}.mp3")

    begin
      Rails.logger.info 'Starting OGA to MP3 conversion...'

      # Escribir archivo temporal de entrada
      input_data = oga_file.read
      oga_file.rewind
      File.write(input_path, input_data, mode: 'wb')

      Rails.logger.info "Input file size: #{input_data.size} bytes, written to: #{input_path}"

      # Detectar el comando ffmpeg correcto
      ffmpeg_path = detect_ffmpeg_path
      Rails.logger.info "Using FFmpeg at: #{ffmpeg_path}"

      # Conversión FFmpeg con configuración optimizada y captura de errores
      ffmpeg_cmd = "#{ffmpeg_path} -i #{Shellwords.escape(input_path)} -acodec libmp3lame -b:a 128k -y #{Shellwords.escape(output_path)}"
      Rails.logger.info "FFmpeg command: #{ffmpeg_cmd}"

      # Capturar stdout y stderr
      result = `#{ffmpeg_cmd} 2>&1`
      success = $?.success?

      Rails.logger.info "FFmpeg result: #{success}, output: #{result.strip}"

      unless success && File.exist?(output_path)
        Rails.logger.error "FFmpeg conversion failed. Exit code: #{$?.exitstatus}"
        Rails.logger.error "FFmpeg output: #{result}"
        raise "FFmpeg conversion failed: #{result}"
      end

      # Verificar archivo de salida
      output_size = File.size(output_path)
      Rails.logger.info "Output file size: #{output_size} bytes"

      raise 'Generated MP3 file is empty' if output_size == 0

      # Leer archivo convertido
      mp3_data = File.read(output_path)
      Rails.logger.info "Successfully converted OGA to MP3, final size: #{mp3_data.size} bytes"
      StringIO.new(mp3_data)
    ensure
      # Limpiar archivos temporales
      [input_path, output_path].each do |path|
        if File.exist?(path)
          File.delete(path)
          Rails.logger.debug { "Cleaned up temp file: #{path}" }
        end
      end
    end
  end

  def detect_ffmpeg_path
    # Try common locations for ffmpeg
    paths = ['ffmpeg', '/usr/bin/ffmpeg', '/usr/local/bin/ffmpeg']

    # Add nix store paths (for Railway nixpacks)
    nix_paths = Dir.glob('/nix/store/*/bin/ffmpeg')
    paths.concat(nix_paths)

    paths.each do |path|
      return path if system("#{path} -version > /dev/null 2>&1")
    end

    # Fallback to just 'ffmpeg' and let system handle it
    'ffmpeg'
  end

  def attach_location
    return unless location

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :location,
      fallback_title: location_fallback_title,
      coordinates_lat: location['latitude'],
      coordinates_long: location['longitude']
    )
  end

  def attach_contact
    return unless contact_card

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :contact,
      fallback_title: contact_card['phone_number'].to_s,
      meta: {
        first_name: contact_card['first_name'],
        last_name: contact_card['last_name']
      }
    )
  end

  def file
    @file ||= visual_media_params || params[:message][:voice].presence || params[:message][:audio].presence || params[:message][:document].presence
  end

  def location_fallback_title
    return '' if venue.blank?

    venue[:title] || ''
  end

  def venue
    @venue ||= params.dig(:message, :venue).presence
  end

  def location
    @location ||= params.dig(:message, :location).presence
  end

  def contact_card
    @contact_card ||= params.dig(:message, :contact).presence
  end

  def visual_media_params
    params[:message][:photo].presence&.last ||
      params.dig(:message, :sticker, :thumb).presence ||
      params[:message][:video].presence ||
      params[:message][:video_note].presence
  end

  def transform_business_message!
    params[:message] = params[:business_message] if params[:business_message] && !params[:message]
  end
end

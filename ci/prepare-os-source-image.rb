#!/usr/bin/env ruby

require('fileutils')
require('open3')
require('json')

OS_SOURCE_IMAGE_SEPARATOR = ','
RESOURCE_NOT_FOUND_ERROR = 'Could not find resource'
IMAGE_DOWNLOAD_DIRECTORY = '/tmp'
S3CMD_FLAGS = " \
    --access_key='#{ENV['S3_ACCESS_KEY']}' \
    --secret_key='#{ENV['S3_SECRET_KEY']}' \
    --ssl \
    --host='#{ENV['S3_HOST']}' \
    --host-bucket='#{ENV['S3_HOST_BUCKET']}' \
"

def write_image_artifact(image_id)
    os_source_image_artifact = ENV['GITLAB_OS_SOURCE_IMAGE_ARTIFACT']
    os_source_image_artifact_dir = File.dirname(os_source_image_artifact)
    FileUtils.mkdir_p(os_source_image_artifact_dir)
    File.write(os_source_image_artifact, image_id)
    STDERR.puts("Written source image ID \"#{image_id}\" to \"#{os_source_image_artifact}\"")
end

def find_in_openstack(possible_images)
    std_out, std_err, status = Open3.capture3('openstack image list -f json')
    if status.exitstatus != 0
        abort("Error getting images from OpenStack: #{std_err}")
    end
    images = JSON.parse(std_out).select {|item| possible_images.include?(item['Name'])}
    if images.size > 0
        return images.last['ID']
    end
    return nil
end

def validate_object_store_access
    # Validate S3 credentials (will fail if invalid)
    s3_validator = "#{ENV['GITLAB_HGI_CI_DIR']}/validate-s3.sh"
    STDERR.puts("Validating S3 credentials using: #{s3_validator}")
    return system(s3_validator)
end

def find_in_object_store(possible_images)
    std_out, std_err, status = Open3.capture3("s3cmd ls #{S3CMD_FLAGS} 's3://#{ENV['S3_IMAGE_BUCKET']}/'")
    if status.exitstatus != 0
        abort("Could not connect to the object store: #{std_err}")
    end
    possible_images.each do |image|
        std_out.each_line do |line|
            if line.strip.end_with?("/#{image}")
                STDERR.puts("Found the image \"#{image}\" in the object store")
                return image
            end
        end
    end
    return nil
end

def load_from_object_store(image)
    STDERR.puts("downloading #{image} from the object store to #{IMAGE_DOWNLOAD_DIRECTORY}")
    system("s3cmd get #{S3CMD_FLAGS} --force 's3://#{ENV['S3_IMAGE_BUCKET']}/#{image}' '#{IMAGE_DOWNLOAD_DIRECTORY}'") or abort
    STDERR.puts('Uploading image to OpenStack...')
    std_out, std_err, status = Open3.capture3(
        "openstack image create --file '#{IMAGE_DOWNLOAD_DIRECTORY}/#{image}' -c id -f value '#{image}'")
    if status.exitstatus != 0
        abort("Error uploading image to OpenStack: #{std_err}")
    else
        return std_out.strip
    end
    return nil
end

def main
    possible_images = ENV['OS_SOURCE_IMAGE'].split(OS_SOURCE_IMAGE_SEPARATOR)

    image_id = find_in_openstack(possible_images)

    if image_id.nil?
        STDERR.puts('No matching images found in OpenStack - checking for the images in the object store')
        unless validate_object_store_access
            abort('Failed to validate access to the object store')
        end
        image = find_in_object_store(possible_images)
        unless image.nil?
            image_id = load_from_object_store(image)
        end
    end
    if image_id.nil?
        abort("No matching images found in either OpenStack or in the object store: #{possible_images}")
    end

    write_image_artifact(image_id)
end

main()

#!/usr/bin/env ruby

require('fileutils')
require('open3')
require('json')
require 'optparse'

OS_IMAGE_LIMIT = 1000
OS_SOURCE_IMAGE_SEPARATOR = ','
RESOURCE_NOT_FOUND_ERROR = 'Could not find resource'
IMAGE_DOWNLOAD_DIRECTORY = '/tmp'
CLI_PARAMETERS = ["os_image", "s3_image_bucket"]
USAGE =  "Usage: prepare-os-image.rb #{CLI_PARAMETERS.join(" ")}"


def find_in_openstack(possible_images)
    std_out, std_err, status = Open3.capture3("openstack image list --limit #{OS_IMAGE_LIMIT} -f json")
    if status.exitstatus != 0
        abort("Error getting images from OpenStack: #{std_err}")
    end
    image_list = JSON.parse(std_out)
    if image_list.size >= OS_IMAGE_LIMIT
      abort("Received too many images from OpenStack, cannot continue (suggest raising OS_IMAGE_LIMIT or delete some images)")
    end
    images = image_list.select {|item| possible_images.include?(item['Name'])}
    if images.size > 0
        return images.last['ID']
    end
    return nil
end


def find_in_object_store(possible_images, image_bucket)
    std_out, std_err, status = Open3.capture3("s3cmd ls 's3://#{image_bucket}/'")
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


def load_from_object_store(image, image_bucket)
    STDERR.puts("Downloading #{image} from the object store to #{IMAGE_DOWNLOAD_DIRECTORY}")
    system("s3cmd get --force 's3://#{image_bucket}/#{image}' '#{IMAGE_DOWNLOAD_DIRECTORY}' >&2") or abort
    STDERR.puts("Uploading #{image} to Glance...")
    std_out, std_err, status = Open3.capture3(
        "openstack image create --file '#{IMAGE_DOWNLOAD_DIRECTORY}/#{image}' -c id -f value '#{image}'")
    if status.exitstatus != 0
        abort("Error uploading image to OpenStack: #{std_err}")
    else
        return std_out.strip
    end
    return nil
end


def run(os_image, s3_image_bucket)
    possible_images = os_image.split(OS_SOURCE_IMAGE_SEPARATOR)

    image_id = find_in_openstack(possible_images)

    if image_id.nil?
        STDERR.puts('No matching images found in OpenStack - checking for the images in the object store')
        image = find_in_object_store(possible_images, s3_image_bucket)
        unless image.nil?
            image_id = load_from_object_store(image, s3_image_bucket)
        end
    end
    if image_id.nil?
        abort("No matching images found in either OpenStack or in the object store: #{possible_images}")
    end

    STDOUT.puts(image_id)
end


def main(positional_arguments)
    if positional_arguments.length < CLI_PARAMETERS.length
        success = positional_arguments.length == 0 || (positional_arguments.length == 1 \
                      && (positional_arguments[0] == "-h" || positional_arguments[0] == "--help"))
       STDERR.puts(USAGE)
       exit(success ? 0 : 1)
    end

    os_image, s3_image_bucket = ARGV

    run(os_image, s3_image_bucket)
end

main(ARGV)

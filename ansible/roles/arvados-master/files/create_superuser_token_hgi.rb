#!/usr/bin/env ruby
# Copyright (C) The Arvados Authors. All rights reserved.
#
# SPDX-License-Identifier: AGPL-3.0

# Install the supplied string as an API token that
# authenticates to the system user account.
#
# Print the token on stdout.

module CreateSuperUserToken
  require File.dirname(__FILE__) + '/../config/boot'
  require File.dirname(__FILE__) + '/../config/environment'

  include ApplicationHelper

  def create_superuser_token supplied_token=nil
    act_as_system_user do
      # If token is supplied and exists, verify that it indeed is a superuser token
      if supplied_token
        api_client_auth = ApiClientAuthorization.
          where(api_token: supplied_token).
          first
        if !api_client_auth
          # fall through to create a token
        elsif !api_client_auth.user.uuid.match(/-000000000000000$/)
          raise "Token exists but is not a superuser token."
        elsif api_client_auth.scopes != ['all']
          raise "Token exists but has limited scope #{api_client_auth.scopes.inspect}."
        else
          return api_client_auth.api_token
        end
      end

      # need to create a token
      if !api_client_auth
        # Get (or create) trusted api client
        apiClient =  ApiClient.
          find_or_create_by(url_prefix: "ssh://root@localhost/",
                            is_trusted: true)

        # none exist; create one with the supplied token
        if !api_client_auth
          api_client_auth = ApiClientAuthorization.
            new(user: system_user,
              api_client_id: apiClient.id,
              created_by_ip_address: '::1',
              api_token: supplied_token)
          api_client_auth.save!
        end
      end

      return api_client_auth.api_token
    end
  end
end

include CreateSuperUserToken

supplied_token = ARGV[0]

token = CreateSuperUserToken.create_superuser_token supplied_token
puts token

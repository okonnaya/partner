# frozen_string_literal: true

require 'active_record'

class User < ActiveRecord::Base
    self.primary_key = :user_id
end

class Note < ActiveRecord::Base
end

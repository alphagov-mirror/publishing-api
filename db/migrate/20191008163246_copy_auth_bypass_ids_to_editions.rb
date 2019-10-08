class CopyAuthBypassIdsToEditions < ActiveRecord::Migration[5.2]
  def change
    AccessLimit.all.each do |access_limit|
      edition = access_limit.edition

      if edition
        edition.update!(auth_bypass_ids: access_limit.auth_bypass_ids)
      end
    end
  end
end

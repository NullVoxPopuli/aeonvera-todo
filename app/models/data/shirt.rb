# frozen_string_literal: true

# == Schema Information
#
# Table name: line_items
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  price                  :decimal(, )
#  host_id                :integer
#  deleted_at             :datetime
#  created_at             :datetime
#  updated_at             :datetime
#  item_type              :string(255)
#  picture_file_name      :string(255)
#  picture_content_type   :string(255)
#  picture_file_size      :integer
#  picture_updated_at     :datetime
#  reference_id           :integer
#  metadata               :text
#  expires_at             :datetime
#  host_type              :string(255)
#  description            :text
#  schedule               :text
#  starts_at              :time
#  ends_at                :time
#  duration_amount        :integer
#  duration_unit          :integer
#  registration_opens_at  :datetime
#  registration_closes_at :datetime
#  becomes_available_at   :datetime
#  initial_stock          :integer          default(0), not null
#
# Indexes
#
#  index_line_items_on_host_id_and_host_type                (host_id,host_type)
#  index_line_items_on_host_id_and_host_type_and_item_type  (host_id,host_type,item_type)
#

class Shirt < LineItem::Shirt
  # this will need to go away when I get rid of this class.
  # namespaces are easy in ember :-)
  has_attached_file :picture,
                    preserve_files: true,
                    keep_old_files: true,
                    path: '/assets/line_item/shirt/:id/picture_:style.:extension',
                    styles: {
                      thumb: '128x128>',
                      medium: '300x300>'
                    }

  class << self
    def sti_name
      LineItem::Shirt.name
    end
  end
end

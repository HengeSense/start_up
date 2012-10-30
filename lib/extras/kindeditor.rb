module Kindeditor
  module Helper
    def kindeditor_tag(name, content = nil, options = {})
      id = sanitize_to_id(name)
      input_html = {:id => id}.merge(options.delete(:input_html) || {})
      output = ActiveSupport::SafeBuffer.new
      output << text_area_tag(name, content, input_html)
      output << javascript_tag(js_replace(id, options))
    end

    def kindeditor(name, method, options = {})
      input_html = (options.delete(:input_html) || {})
      hash = input_html.stringify_keys
      instance_tag = ActionView::Base::InstanceTag.new(name, method, self, options.delete(:object))
      instance_tag.send(:add_default_name_and_id, hash)
      output_buffer = ActiveSupport::SafeBuffer.new
      output_buffer << instance_tag.to_text_area_tag(input_html)
      js = js_replace(hash['id'], options)
      output_buffer << javascript_tag(js)
    end

    private
    def js_replace(dom_id, options = {})
      if options[:items].nil?
        options[:items] = %w(fontname fontsize | forecolor hilitecolor bold italic underline
            removeformat | justifyleft justifycenter justifyright insertorderedlist
            insertunorderedlist | table | emoticons image link)
      end

      js_options = get_options(options)

      "if(window.kindeditor_fields === undefined) {
           window.kindeditor_fields = [];
       }

       window.kindeditor_fields.push({
           id: '##{dom_id}',
           config: {
             #{js_options},
             uploadJson: '/kindeditor/upload'
           }
       });"
    end

    def get_options(options)
      str = []
      options.delete(:uploadJson)
      options.delete(:fileManagerJson)

      options.reverse_merge!(:width => '100%')
      options.reverse_merge!(:height => 300)

      options.reverse_merge!(:allowFileManager => false)
      options.reverse_merge!(:allowFlashUpload => false)
      options.reverse_merge!(:allowFileUpload => false)
      options.reverse_merge!(:allowMediaUpload => false)

      options.each do |key, value|
        item = case value
                 when String then
                   value.split(//).first == '^' ? value.slice(1..-1) : "'#{value}'"
                 when Hash then
                   "{ #{get_options(value)} }"
                 when Array then
                   arr = value.collect { |v| "'#{v}'" }
                   "[ #{arr.join(',')} ]"
                 else
                   value
               end
        str << %Q{"#{key}": #{item}}
      end
      str.sort.join(',')
    end
  end

  module Builder
    def kindeditor(method, options = {})
      @template.send("kindeditor", @object_name, method, objectify_options(options))
    end
  end
end

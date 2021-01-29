local ffi         = require("ffi");
local ffi_cdef    = ffi.cdef
local ffi_load    = ffi.load
local ffi_new     = ffi.new

local wirefilter = ffi_load "wirefilter";

ffi_cdef [[
  
  typedef struct wirefilter_scheme wirefilter_scheme_t;
  typedef struct wirefilter_execution_context wirefilter_execution_context_t;
  typedef struct wirefilter_filter_ast wirefilter_filter_ast_t;
  typedef struct wirefilter_filter wirefilter_filter_t;
  
  typedef struct {
      const char *data;
      size_t length;
  } wirefilter_rust_allocated_str_t;
  
  typedef struct {
      const char *data;
      size_t length;
  } wirefilter_static_rust_allocated_str_t;
  
  typedef struct {
      const char *data;
      size_t length;
  } wirefilter_externally_allocated_str_t;
  
  typedef struct {
      const unsigned char *data;
      size_t length;
  } wirefilter_externally_allocated_byte_arr_t;
  
  typedef union {
      uint8_t success;
      struct {
          uint8_t _res1;
          wirefilter_rust_allocated_str_t msg;
      } err;
      struct {
          uint8_t _res2;
          wirefilter_filter_ast_t *ast;
      } ok;
  } wirefilter_parsing_result_t;
  
  typedef enum {
      WIREFILTER_TYPE_IP,
      WIREFILTER_TYPE_BYTES,
      WIREFILTER_TYPE_INT,
      WIREFILTER_TYPE_BOOL,
  } wirefilter_type_t;
  
  wirefilter_scheme_t *wirefilter_create_scheme();
  void wirefilter_free_scheme(wirefilter_scheme_t *scheme);
  
  void wirefilter_add_type_field_to_scheme(
      wirefilter_scheme_t *scheme,
      wirefilter_externally_allocated_str_t name,
      wirefilter_type_t type
  );
  
  wirefilter_parsing_result_t wirefilter_parse_filter(
      const wirefilter_scheme_t *scheme,
      wirefilter_externally_allocated_str_t input
  );
  
  void wirefilter_free_parsing_result(wirefilter_parsing_result_t result);
  
  wirefilter_filter_t *wirefilter_compile_filter(wirefilter_filter_ast_t *ast);
  void wirefilter_free_compiled_filter(wirefilter_filter_t *filter);
  
  wirefilter_execution_context_t *wirefilter_create_execution_context(
      const wirefilter_scheme_t *scheme
  );
  void wirefilter_free_execution_context(
      wirefilter_execution_context_t *exec_ctx
  );
  
  void wirefilter_add_int_value_to_execution_context(
      wirefilter_execution_context_t *exec_ctx,
      wirefilter_externally_allocated_str_t name,
      int32_t value
  );
  
  void wirefilter_add_bytes_value_to_execution_context(
      wirefilter_execution_context_t *exec_ctx,
      wirefilter_externally_allocated_str_t name,
      wirefilter_externally_allocated_byte_arr_t value
  );
  
  void wirefilter_add_ipv6_value_to_execution_context(
      wirefilter_execution_context_t *exec_ctx,
      wirefilter_externally_allocated_str_t name,
      uint8_t value[16]
  );
  
  void wirefilter_add_ipv4_value_to_execution_context(
      wirefilter_execution_context_t *exec_ctx,
      wirefilter_externally_allocated_str_t name,
      uint8_t value[4]
  );
  
  void wirefilter_add_bool_value_to_execution_context(
      wirefilter_execution_context_t *exec_ctx,
      wirefilter_externally_allocated_str_t name,
      bool value
  );
  
  bool wirefilter_match(
      const wirefilter_filter_t *filter,
      const wirefilter_execution_context_t *exec_ctx
  );
  
  bool wirefilter_filter_uses(
      const wirefilter_filter_ast_t *ast,
      wirefilter_externally_allocated_str_t field_name
  );
  
  uint64_t wirefilter_get_filter_hash(const wirefilter_filter_ast_t *ast);
  
  wirefilter_rust_allocated_str_t wirefilter_serialize_filter_to_json(
      const wirefilter_filter_ast_t *ast
  );
  
  void wirefilter_free_string(wirefilter_rust_allocated_str_t str);
  
  wirefilter_static_rust_allocated_str_t wirefilter_get_version();


]]

local _M = {
    _VERSION    = '1.0.0',
    types = {
        BYTES   = ffi.C.WIREFILTER_TYPE_BYTES,
        IP      = ffi.C.WIREFILTER_TYPE_IP,
        BOOL    = ffi.C.WIREFILTER_TYPE_BOOL,
        INT     = ffi.C.WIREFILTER_TYPE_INT
    }
}
local mt = {
    __index = _M
}

function _M:new(args)
    local args          = args or {}
    local fields        = args.fields or {}
    local filter        = args.filter or ""
    local fields_map    = {}

    local scheme, err = self:init_scheme(fields, fields_map)
    if (scheme == nil) then
        return nil, err
    end

    local filter, err = self:create_filter(scheme, args.filter)
    if (filter == nil) then
        return nil, err
    end

    local self = {
        scheme        = scheme,
        filter        = filter,
        fields_map    = fields_map
    }

    return setmetatable(self, mt)
end

function _M:create_execution_context(scheme)
    local context = ffi_new("wirefilter_execution_context_t*")
    local context = wirefilter.wirefilter_create_execution_context(scheme)
    if (context == nil) then
        return nil, "could not create execution context"
    end

    return context
end

function _M:match(filter, context)
    local match_result = wirefilter.wirefilter_match(filter, context)
    return match_result
end

function _M:free_execution_context(context)
    wirefilter.wirefilter_free_execution_context(context)
end

function _M:exec(values)

    local context, err = self:create_execution_context(self.scheme)
    if (context == nil) then
        return nil, err
    end

    for name, value in pairs(values) do
        local result, err = self:add_value_to_execution_context(context, {
            name = name,
            value = value
        })

        if not result then
            return nil, err
        end

    end

    local match_result = self:match(self.filter, context)
    self:free_execution_context(context)

    return match_result

end

function _M:get_field(value)
    local field = self.fields_map[value.name]
    if (field == nil) then
        return nil, "field does not exist"
    end

    return field
end

function _M:add_value_to_execution_context(context, value)
    local field, err = self:get_field(value)
    if (field == nil) then
        return false, err
    end

    if (field == self.types.BYTES) then
        wirefilter.wirefilter_add_bytes_value_to_execution_context(context, self:wirefilter_string(value.name),
            self:wirefilter_byte(value.value))

    elseif (field == self.types.BOOL) then
        wirefilter.wirefilter_add_bool_value_to_execution_context(context, self:wirefilter_string(value.name),
            value.value)

    elseif (field == self.types.INT) then
        local int_value, err = self:wirefilter_int(value.value)
        if (int_value == nil) then
            return false, err
        end

        wirefilter.wirefilter_add_int_value_to_execution_context(context, self:wirefilter_string(value.name), int_value)

    elseif (field == self.types.IP) then
        local ip_value, err = self:wirefilter_ip(value.value)
        if (ip_value == nil) then
            return false, err
        end

        wirefilter.wirefilter_add_ipv4_value_to_execution_context(context, self:wirefilter_string(value.name), ip_value)
    end

    return true
end

function _M:clear(filter, scheme)
    self:free_compiled_filter(filter)
    self:free_scheme(scheme)
end

function _M:free_compiled_filter(filter)
    wirefilter.wirefilter_free_compiled_filter(filter);
end

function _M:free_scheme(scheme)
    wirefilter.wirefilter_free_scheme(scheme);
end

function _M:create_filter(scheme, filter_string)

    local result = ffi_new("wirefilter_parsing_result_t")
    local result = wirefilter.wirefilter_parse_filter(scheme, self:wirefilter_string(filter_string))

    if (result.success ~= 1) then
        return nil, "could not parse filter"
    end

    if (result.ok.ast == nil) then
        return nil, "could not parse filter"
    end

    local filter = ffi_new("wirefilter_filter_t*")
    local filter = wirefilter.wirefilter_compile_filter(result.ok.ast)

    if (filter == nil) then
        return nil, "could not compile filter"
    end

    return filter

end

function _M:init_scheme(fields, fields_map)

    local scheme, err = self:create_scheme()

    if (scheme == nil) then
        return nil, err
    end

    for name, type in pairs(fields) do
        self:add_type_field_to_scheme(scheme, fields_map, name, type)
    end

    return scheme

end

function _M:create_scheme()
    local scheme = ffi_new("wirefilter_scheme_t*")
    local scheme = wirefilter.wirefilter_create_scheme()

    if (scheme == nil) then
        return nil, "could not create scheme"
    end

    return scheme
end

function _M:add_type_field_to_scheme(scheme, fields_map, name, type)
    wirefilter.wirefilter_add_type_field_to_scheme(scheme, self:wirefilter_string(name), type)
    fields_map[name] = type
end

function _M:wirefilter_int(value)
    local value = tonumber(value)
    if (value == nil) then
        return nil, "number is not valid"
    end
    return value
end

function _M:wirefilter_string(value)
    local value = tostring(value)
    local str = ffi_new("wirefilter_externally_allocated_str_t", {
        data = value,
        length = string.len(value)
    })
    return str
end

function _M:wirefilter_byte(value)
    local value = tostring(value)
    local bytes = ffi_new("wirefilter_externally_allocated_byte_arr_t", {
        data = value,
        length = string.len(value)
    })
    return bytes
end

function _M:wirefilter_ip(value)

    local ip_tab = {}

    for s in string.gmatch(value, "[^.]+") do
        local ip_seg = tonumber(s)
        if (ip_seg ~= nil and ip_seg >= 0 and ip_seg <= 255) then
            table.insert(ip_tab, ip_seg)
        end
    end

    if (#ip_tab ~= 4) then
        return nil, "invalid ipv4 address"
    end

    local ip = ffi_new("uint8_t[4]", ip_tab)
    return ip
end

return _M

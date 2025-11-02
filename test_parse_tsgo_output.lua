local M = {}

-- Custom inspect function for plain Lua
local function inspect(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) == 'number' then
        s = s .. '[' .. k .. ']=' .. inspect(v) .. ', '
      else
        s = s .. k .. '=' .. inspect(v) .. ', '
      end
    end
    return s .. '}'
  else
    return tostring(o)
  end
end

M.parse_tsgo_output = function(output, config)
  local errors = {}
  local files = {}

  if output == nil then
    return { errors = errors, files = files }
  end

  for _, line in ipairs(output) do
    local filename, lineno, colno, message = line:match("^(.+):(%d+):(%d+)%s*-%s*error%s*TS%d+:%s*(.+)$")
    if filename ~= nil then
      local text = message
      table.insert(errors, {
        filename = filename,
        lnum = tonumber(lineno),
        col = tonumber(colno),
        text = text,
        type = "E",
      })

      local found = false
      for _, f in ipairs(files) do
        if f == filename then
          found = true
          break
        end
      end
      if not found then
        table.insert(files, filename)
      end
    end
  end

  return { errors = errors, files = files }
end

local config = { pretty_errors = false } -- Mock config

-- Test Case 1: Exact error output provided by user
local error_output_1 = {
  "app/[locale]/start/(actions)/import-asin/_components/starter-additional-asin-options.tsx:32:18 - error TS1005: ',' expected."
}
local result_1 = M.parse_tsgo_output(error_output_1, config)
print("--- Test Case 1 ---")
if #result_1.errors == 1 and result_1.errors[1].filename == "app/[locale]/start/(actions)/import-asin/_components/starter-additional-asin-options.tsx" and result_1.errors[1].lnum == 32 and result_1.errors[1].col == 18 and result_1.errors[1].text == ",' expected." then
  print("Test 1 Passed")
else
  print("Test 1 Failed")
  print(inspect(result_1.errors))
end

-- Test Case 2: Multi-line error output
local error_output_2 = {
  "src/components/MyComponent.tsx:10:5 - error TS2322: Type 'string' is not assignable to type 'number'.",
  "src/utils/helper.ts:5:1 - error TS2304: Cannot find name 'someFunction'."
}
local result_2 = M.parse_tsgo_output(error_output_2, config)
print("\n--- Test Case 2 ---")
if #result_2.errors == 2 and result_2.errors[1].filename == "src/components/MyComponent.tsx" and result_2.errors[2].filename == "src/utils/helper.ts" then
  print("Test 2 Passed")
else
  print("Test 2 Failed")
  print(inspect(result_2.errors))
end

-- Test Case 3: Error output with different TS error code
local error_output_3 = {
  "test/foo.ts:1:1 - error TS2551: Property 'bar' does not exist on type 'Foo'. Did you mean 'baz'?"
}
local result_3 = M.parse_tsgo_output(error_output_3, config)
print("\n--- Test Case 3 ---")
if #result_3.errors == 1 and result_3.errors[1].text == "Property 'bar' does not exist on type 'Foo'. Did you mean 'baz'?" then
  print("Test 3 Passed")
else
  print("Test 3 Failed")
  print(inspect(result_3.errors))
end

-- Test Case 4: Error output with a different file path structure
local error_output_4 = {
  "./nested/path/index.ts:5:10 - error TS7006: Parameter 'event' implicitly has an 'any' type."
}
local result_4 = M.parse_tsgo_output(error_output_4, config)
print("\n--- Test Case 4 ---")
if #result_4.errors == 1 and result_4.errors[1].filename == "./nested/path/index.ts" and result_4.errors[1].lnum == 5 then
  print("Test 4 Passed")
else
  print("Test 4 Failed")
  print(inspect(result_4.errors))
end

-- Test Case 5: Output with no errors
local error_output_5 = {
  "No errors found.",
  "Watching for file changes."
}
local result_5 = M.parse_tsgo_output(error_output_5, config)
print("\n--- Test Case 5 ---")
if #result_5.errors == 0 then
  print("Test 5 Passed")
else
  print("Test 5 Failed")
  print(inspect(result_5.errors))
end

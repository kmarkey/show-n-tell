local function isEmpty(s)
  return s == nil or s == ''
end

local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local function getVal(s)
  return pandoc.utils.stringify(s)
end

local function is_equal (s, val)
  if isEmpty(s) then return false end
  if getVal(s) == val then return true end

  return false
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function Meta(m)
--[[
This function checks that the value the user set is ok and stops with an error message if no.
yamlelement: the yaml metadata. e.g. m["titlepage-theme"]["page-align"]
yamltext: page, how to print the yaml value in the error message. e.g. titlepage-theme: page-align
okvals: a text table of ok styles. e.g. {"right", "center"}
--]]
  local function check_yaml (yamlelement, yamltext, okvals)
    choice = pandoc.utils.stringify(yamlelement)
    if not has_value(okvals, choice) then
      print("\n\ntitlepage extension error: " .. yamltext .. " is set to " .. choice .. ". It can be " .. pandoc.utils.stringify(table.concat(okvals, ", ")) .. ".\n\n")
      return false
    else
      return true
    end

    return true
  end

--[[
This function gets the value of something like titlepage-theme.title-style and sets a value titlepage-theme.title-style.plain (for example). It also
does error checking against okvals. "plain" is always ok and if no value is set then the style is set to plain.
page: titlepage or coverpage
styleement: page, title, subtitle, header, footer, affiliation, etc
okvals: a text table of ok styles. e.g. {"plain", "two-column"}
--]]
  local function set_style (page, styleelement, okvals)
    yamltext = page .. "-theme" .. ": " .. styleelement .. "-style"
    yamlelement = m[page .. "-theme"][styleelement .. "-style"]
    if not isEmpty(yamlelement) then
      ok = check_yaml (yamlelement, yamltext, okvals)
      if ok then
        m[page .. "-style-code"][styleelement] = {}
        m[page .. "-style-code"][styleelement][getVal(yamlelement)] = true
      else
        error()
      end
    else
--      print("\n\ntitlepage extension error: " .. yamltext .. " needs a value. Should have been set in titlepage-theme lua filter.\n\n")
--      error()
        m[page .. "-style-code"][styleelement] = {}
        m[page .. "-style-code"][styleelement]["plain"] = true
    end
  end

--[[
This function assigns the themevals to the meta data
--]]
  local function assign_value (tab)
    for i, value in pairs(tab) do
      if isEmpty(m['titlepage-theme'][i]) then
        m['titlepage-theme'][i] = value
      end
    end

    return m
  end

  local titlepage_table = {
    
    ["vline"] = function (m)
      themevals = {
        ["elements"] = {
          pandoc.MetaInlines{pandoc.RawInline("latex","\\titleblock")}, 
          pandoc.MetaInlines{pandoc.RawInline("latex","\\dateblock")},
          pandoc.MetaInlines{pandoc.RawInline("latex","\\authorblock")},
          pandoc.MetaInlines{pandoc.RawInline("latex","\\vfill")},
          pandoc.MetaInlines{pandoc.RawInline("latex","\\footerblock")}
          },
        ["top-space"] = "2.75in",
        ["page-align"] = "left",
        ["title-style"] = "plain",
        ["title-fontsize"] = "28",
        ["title-fontsize"] = "28",
        ["title-fontstyle"] = "bfseries",
        ["title-space-after"] = pandoc.MetaInlines{
          pandoc.RawInline("latex","4\\baselineskip")},
        ["subtitle-fontstyle"] = "textit",
        ["subtitle-fontsize"] = "20",
        ["date-fontsize"] = "14",
        ["author-style"] = "plain-with-and",
        ["author-fontsize"] = "14",
        ["author-space-after"] = pandoc.MetaInlines{
          pandoc.RawInline("latex","2\\baselineskip")},
        ["affiliation-style"] = "numbered-list",
        ["affiliation-fontstyle"] = {"large"},
        ["affiliation-space-after"] = "1pt",
        ["footer-style"] = "none",
        ["footer-fontsize"] = "10",
        ["footer-space-after"] = "1pt",
        ["logo-size"] = pandoc.MetaInlines{
          pandoc.RawInline("latex","1.83in")},
        ["logo-space-after"] = pandoc.MetaInlines{
          pandoc.RawInline("latex","0.1\\textheight")},
        ["vrule-width"] = "2.833in",
        ["vrule-space"] = "0.375in",
        ["vrule-align"] = "left",
        ["vrule-color"] = "srebblue",
        ["vrule-text"] = "Southern Regional Education Board",
        ["vrule-text-color"] = "white",
        ["vrule-hspace"] = "0.50in"
        }
      assign_value(themevals)
        
      return m
    end,

    ["none"] = function (m) return m end
  }
  
  m['titlepage-file'] = false
  
  -- if no titlepage then default to vline
  if isEmpty(m.titlepage) then m['titlepage'] = "vline" end
  if getVal(m.titlepage) == "false" then m['titlepage'] = "none" end
  if getVal(m.titlepage) == "true" then m['titlepage'] = "plain" end
  if getVal(m.titlepage) == "none" then 
    m['titlepage-true'] = false
  else
    m['titlepage-true'] = true 
  end
  choice = pandoc.utils.stringify(m.titlepage)
  okvals = {"plain", "vline", "vline-text", "bg-image", "colorbox", "academic", "formal", "classic-lined"}
  isatheme = has_value (okvals, choice)
  if not isatheme and choice ~= "none" then
    if not file_exists(choice) then
      error("titlepage extension error: titlepage can be a tex file or one of the themes: " .. pandoc.utils.stringify(table.concat(okvals, ", ")) .. ".")
    else
      m['titlepage-file'] = true
      m['titlepage-filename'] = choice
      m['titlepage'] = "file"
    end
  end
  if m['titlepage-file'] and not isEmpty(m['titlepage-theme']) then
    print("\n\ntitlepage extension message: since you passed in a static titlepage file, titlepage-theme is ignored.n\n")
  end
  if not m['titlepage-file'] and choice ~= "none" then
    if isEmpty(m['titlepage-theme']) then
      m['titlepage-theme'] = {}
    end
    titlepage_table[choice](m) -- add the theme defaults
  end

-- Only for themes
-- titlepage-theme will exist if using a theme
if not m['titlepage-file'] and m['titlepage-true'] then
--[[
Error checking and setting the style codes
--]]
  -- Style codes
  m["titlepage-style-code"] = {}
  okvals = {"none", "plain", "colorbox", "doublelinewide", "doublelinetight"}
  set_style("titlepage", "title", okvals)
  set_style("titlepage", "footer", okvals)
  set_style("titlepage", "header", okvals)
  set_style("titlepage", "date", okvals)
  okvals = {"none", "plain", "plain-with-and", "superscript", "superscript-with-and", "two-column", "author-address"}
  set_style("titlepage", "author", okvals)
  okvals = {"none", "numbered-list", "numbered-list-with-correspondence"}
  set_style("titlepage", "affiliation", okvals)
  if is_equal(m['titlepage-theme']["author-style"], "author-address") and is_equal(m['titlepage-theme']["author-align"], "spread") then
    error("\n\nquarto_titlepages error: If author-style is two-column, then author-align cannot be spread.\n\n")
  end

--[[
Set the fontsize defaults
if page-fontsize was passed in or if fontsize passed in but not spacing
--]]
  for key, val in pairs({"title", "author", "affiliation", "footer", "header", "date"}) do
    if isEmpty(m["titlepage-theme"][val .. "-fontsize"]) then
      if not isEmpty(m["titlepage-theme"]["page-fontsize"]) then
        m["titlepage-theme"][val .. "-fontsize"] = getVal(m["titlepage-theme"]["page-fontsize"])
      end
    end
  end
  for key, val in pairs({"page", "title", "subtitle", "author", "affiliation", "footer", "header", "date"}) do
    if not isEmpty(m['titlepage-theme'][val .. "-fontsize"]) then
      if isEmpty(m['titlepage-theme'][val .. "-spacing"]) then
        m['titlepage-theme'][val .. "-spacing"] = 1.2*getVal(m['titlepage-theme'][val .. "-fontsize"])
      end
    end
  end

--[[
Set author sep character
--]]
  if isEmpty(m['titlepage-theme']["author-sep"]) then
    m['titlepage-theme']["author-sep"] = pandoc.MetaInlines{
          pandoc.RawInline("latex",", ")}
  end
  if getVal(m['titlepage-theme']["author-sep"]) == "newline" then
    m['titlepage-theme']["author-sep"] = pandoc.MetaInlines{
          pandoc.RawInline("latex","\\\\")}
  end

--[[
Set affiliation sep character
--]]
  if isEmpty(m['titlepage-theme']["affiliation-sep"]) then
    m['titlepage-theme']["affiliation-sep"] = pandoc.MetaInlines{
          pandoc.RawInline("latex",",~")}
  end
  if getVal(m['titlepage-theme']["affiliation-sep"]) == "newline" then
    m['titlepage-theme']["affiliation-sep"] = pandoc.MetaInlines{
          pandoc.RawInline("latex","\\\\")}
  end
  
--[[
Set bg-image defaults
--]]
  if not isEmpty(m['titlepage-bg-image']) then
    if isEmpty(m['titlepage-theme']["bg-image-size"]) then
      m['titlepage-theme']["bg-image-size"] = pandoc.MetaInlines{
          pandoc.RawInline("latex","\\paperwidth")}
    end
    if not isEmpty(m["titlepage-theme"]["bg-image-location"]) then
      okvals = {"ULCorner", "URCorner", "LLCorner", "LRCorner", "TileSquare", "Center"}
      ok = check_yaml (m["titlepage-theme"]["bg-image-location"], "titlepage-theme: bg-image-location", okvals)
      if not ok then error("") end
    end  
  end

end -- end the theme section

  return m
  
end



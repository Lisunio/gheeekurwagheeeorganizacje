function OrgTrim(value)
    if type(value) ~= 'string' then return '' end
    return value:gsub('^%s+', ''):gsub('%s+$', '')
end

function OrgShort(value, max)
    value = OrgTrim(value)
    return value:sub(1, max or 8)
end

function OrgCanUse(rank, required)
    return (tonumber(rank) or 0) >= (tonumber(required) or 0)
end

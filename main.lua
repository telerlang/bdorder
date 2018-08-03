--打开文件，如果打开失败则显示errormsg后退出
function openfile(filename, attr, errormsg)
    local f = io.open(filename, attr)
    if not f then
        print(errormsg)
        os.exit()
    end
    return f
end

--[[
将带双引号或不带双引号的csv行，csv字段内不能有逗号（有的话会拆分错误），用逗号分隔输出成table。
输入测试值：
'181175978,客服电话,未竣工,30'
'"111","adsf   afds","asdfsadf    "'
",,shou,wang,1,,15,,"
--]]
function splitbycomma(instr)
    local splitlist = {}
    local temp = string.gsub(instr, '[ "]', "") --去掉空格和双引号
    local j = 1
    local start = 1
    for i = 1, string.len(temp) do
        if string.byte(temp, i) == 44 then --44是 , 的字符编码
            if start == i then
                splitlist[j] = nil
                start = i + 1
                j = j + 1
            else
                splitlist[j] = string.sub(temp, start, i - 1)
                start = i + 1
                j = j + 1
            end
        end
        if i == string.len(temp) and start < i then
            splitlist[j] = string.sub(temp, start, i)
        end
    end
    return splitlist
end

--如果表中有nil值，则须用此函数将表中的元素由大到小组合成字符串
function sortfieldtostr(t1, sep)
    local str = ""
    local maxno = 0
    for i, v in pairs(t1) do
        if i > maxno then
            maxno = i
        end
    end
    for i = 1, maxno do
        if t1[i] == nil then
            str = str .. sep
        else
            str = str .. t1[i] .. sep
        end
    end
    return str
end

--将table输出到1个打开的可写的文件中
function tabletocsv(intable, csvfile)
    for i, v in pairs(intable) do
        csvfile:write(sortfieldtostr(v, ",") .. "\n")
    end
end

--将csv文件读到table中，并返回该table
function csvtotable(csvfile)
    local temp = {}
    for record in csvfile:lines() do
        table.insert(temp, splitbycomma(record))
    end
    return temp
end

--对读入cbss.csv的表格按规则处理后，并按第一列ID排序
function createcbss(t1, cbsstitle)
    local cbsstable = {}
    for i, v in pairs(t1) do
        if v[3] == "340" or v[3] == "320" then
            v[3] = "320_340"
        end
        table.insert(cbsstable, {v[1], v[3], v[4]})
        if v[1] ~= v[2] then --如果第一列ID和第二列ID不相等，则生成两行记录。
            table.insert(cbsstable, {v[2], v[3], v[4]})
        end
    end
    table.sort(
        cbsstable,
        function(a, b)
            return a[1] < b[1]
        end
    )
    table.insert(cbsstable, 1, cbsstitle)
    return cbsstable
end

--打开cbss订单输入文件incbssfname，输出规范后的文件cbsstabfname，返回cbss订单table
function createcbsstab(incbssfname, cbsstabfname)
    local f = openfile("cbss.csv", "r", "找不到CBSS/BSS订单明细文件，请将CBSS/BSS订单文件名改为： cbss.csv")
    local cbsstitle = splitbycomma(f:read("l"))
    cbsstitle[2] = cbsstitle[3]
    cbsstitle[3] = cbsstitle[4]
    cbsstitle[4] = nil
    local ctab = csvtotable(f)
    local cbsstab = createcbss(ctab, cbsstitle)
    f:close()
    f = openfile("cbsstable.csv", "w+", "不能生成规范的cbss订单表文件")
    tabletocsv(cbsstab, f)
    f:close()
    return cbsstab
end

--对读入middle.csv的表格放入有效表和无效组表中。
function createmid(midtab, valtab, invaltab)
    local picktab = {
        {"未竣工", "客服电话", 1},
        {"未竣工", "手厅", 2},
        {"未竣工", "网厅", 3},
        {"未竣工", "微厅", 4},
        {"未竣工", "沃扫码", 5},
        {"撤单", "客服电话", 6},
        {"撤单", "手厅", 7},
        {"撤单", "网厅", 8},
        {"撤单", "微厅", 9},
        {"撤单", "沃扫码", 10},
        {"退单", "客服电话", 11},
        {"退单", "手厅", 12},
        {"退单", "网厅", 13},
        {"退单", "微厅", 14},
        {"退单", "沃扫码", 15}
    }
    for i, v in pairs(midtab) do
        if v[1] ~= nil then
            v[1] = "a" .. v[1]
        end
        if v[2] ~= nil then
            v[2] = "a" .. v[2]
        end
        if v[6] ~= nil then
            v[6] = "a" .. v[6]
        end
        if v[5] == "竣工" then
            if v[2] ~= nil then
                table.insert(valtab[1], v)
            else
                table.insert(valtab[2], v)
            end
        else
            for i1, v1 in pairs(picktab) do
                if v[5] == v1[1] and v[3] == v1[2] then
                    table.insert(invaltab[v1[3]], v)
                end
            end
        end
    end
    for i, v in pairs(invaltab) do
        table.sort(
            v,
            function(a, b)
                return a[6] < b[6]
            end
        )
    end
    table.sort(
        valtab[2],
        function(a, b)
            return a[6] < b[6]
        end
    )
end

--二分查找，在表tab中第fieldno个字段查找v值，找到返回表的第几行，找不到返回nil
function binsearch(tab, tablen, fieldno, v)
    local left = 1
    local right = tablen
    local mid = (left + right) // 2
    while right ~= mid do
        if tab[mid][fieldno] == v then
            return mid
        elseif tab[mid][fieldno] < v then
            left = mid + 1
        else
            right = mid - 1
        end
        mid = (left + right) // 2
        if tab[right][fieldno] == v then
            return right
        end
        if tab[left][fieldno] == v then
            return left
        end
        if tab[mid][fieldno] == v then
            return mid
        end
    end
    return nil
end

--在cbsstab中查找有效订单的状态，在每一行最后一个字段后，新增一个字段，并填入查找结果10或320_340或空
function createval(valtab, cbsstab)
    local find = 0
    local cbsstablen = #cbsstab
    for i, v in pairs(valtab) do
        find = binsearch(cbsstab, cbsstablen, 1, v[2])
        if find ~= nil then
            v[7] = cbsstab[find][2]
        end
    end
    return valtab
end

--找出在cbss表中状态为10的，且不在中台订单中的订单号和宽带号码。
function moreper5(valtab,cbsstab)
    local temp={}
    local len=#valtab
    local count=0
    print("test"..valtab[2][2].."debug....")
    for i,v in pairs(cbsstab) do
        if v[2] =="10" then
            if binsearch(valtab,len,2,v[1])==nil then
                table.insert(temp,v)
            else 
                print(i.."debug")
                print(v[1])
            end
        end
    end
    return temp
end

--输出有生产系统订单号的有效订单和BSS/CBSS订单比对结果表csv文件
function outval(valfname, valtab, cbsstab, midtitle)
    local f = openfile(valfname, "w+", "不能创建有效订单检索结果文件")
    local valt = createval(valtab, cbsstab)
    local valtitle = {}
    for i, v in pairs(midtitle) do
        valtitle[i] = v
    end
    valtitle[#valtitle + 1] = "CBSS订单库状态"
    table.insert(valt, 1, valtitle)
    tabletocsv(valt, f)
    f:close()
--    f=openfile("moreper5.csv","w+","不能创建在CBSS不在中台的新增用户明细文件")
--    tabletocsv(moreper5(valtab,cbsstab),f)
--    f:close()
end

--按某个数freq做为间隔，在tab表格的最后一个字段，再新增一个字段并用填入sign，并将所有sign的行填入signtab
function signbyfreq(signtab, tab, freq, sign)
    local temp = {}

--第一次修BUG，增加判断#tab==0，输入空表什么也不做
    if #tab == 0 then
        return
    end
    local fieldend = 0
    local signcount = #tab // freq + 1
    local startno = math.random(#tab)
    for i = 1, signcount do
        temp = tab[startno]
        fieldend = #temp + 1
        temp[fieldend] = sign
        table.insert(signtab, temp)
        startno = (startno + freq) % (#tab) + 1  --第二次修BUG，+1，因为取余的值会为0，循环到下一步出错
    end
end

--处理无效订单，按1%比例标注（即每隔100个）
function signinval(invaltab)
    local signtab = {}
    for i, v in pairs(invaltab) do
        signbyfreq(signtab, v, 100, "yes")
    end
    return signtab
end

--生成无效订单抽查文件csv
function outinvalid(invalfname, invaltab, midtitle)
    local f = openfile(invalfname, "w+", "不能创建无效订单抽查文件")
    local signtab = signinval(invaltab)
    local invaltitle = {}
    for i, v in pairs(midtitle) do
        invaltitle[i] = v
    end
    invaltitle[#invaltitle + 1] = "是否抽查"
    table.insert(signtab, 1, invaltitle)
    tabletocsv(signtab, f)
    f:close()
end

--处理有效且没有生产系统工单号的订单，按1%比例标注（即每隔100个）
function signvalnonum(signtab, valtab)
    signbyfreq(signtab, valtab[2], 100, "yes")
end

--生成没有生产系统订单号的有效订单csv文件
function outvalnonum(valnonumfname, valtab, midtitle)
    local f = openfile(valnonumfname, "w+", "不能创建没有生产系统订单号的有效订单抽查文件")
    local signtab = {}
    signvalnonum(signtab, valtab)
    local invaltitle = {}
    for i, v in pairs(midtitle) do
        invaltitle[i] = v
    end
    invaltitle[#invaltitle + 1] = "是否抽查"
    table.insert(signtab, 1, invaltitle)
    tabletocsv(signtab, f)
    f:close()
end

--主程序开始，打开中台订单明细和BSS/CBSS订单明细
local f = openfile("middle.csv", "r", "找不到中台订单明细文件，请将中台订单文件名改为：  middle.csv")
local midtitle = splitbycomma(f:read("l"))
local midtab = csvtotable(f)
f:close()

--把中台订单明细根据订单来源和订单状态分拣到有效订单表和无效订单表
local validtab = {{}, {}}
local invalidtab = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}
createmid(midtab, validtab, invalidtab)

--生成无效订单和无生产订单号有效订单的抽查表，并输出到csv文件。
outinvalid("invalid.csv", invalidtab, midtitle)
outvalnonum("valnonum.csv", validtab, midtitle)

--将有生产订单号的有效订单和BSS/CBSS订单比对，提取出订单对应的新老用户状态，并输出比对结果csv文件。
local cbsstab = createcbsstab("cbss.csv", "cbsstable.csv")
outval("val.csv", validtab[1], cbsstab, midtitle)

local result =
    [=[
    执行成功，请查看
    无效订单抽查表：invalid.csv
    无生产系统订单号的有效订单抽查表：valnonum.csv
    有生产系统订单号的有效订单和cbss/bss订单核对结果表：val.csv
]=]
print(result)

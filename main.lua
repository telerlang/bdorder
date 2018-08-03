--���ļ��������ʧ������ʾerrormsg���˳�
function openfile(filename, attr, errormsg)
    local f = io.open(filename, attr)
    if not f then
        print(errormsg)
        os.exit()
    end
    return f
end

--[[
����˫���Ż򲻴�˫���ŵ�csv�У�csv�ֶ��ڲ����ж��ţ��еĻ����ִ��󣩣��ö��ŷָ������table��
�������ֵ��
'181175978,�ͷ��绰,δ����,30'
'"111","adsf   afds","asdfsadf    "'
",,shou,wang,1,,15,,"
--]]
function splitbycomma(instr)
    local splitlist = {}
    local temp = string.gsub(instr, '[ "]', "") --ȥ���ո��˫����
    local j = 1
    local start = 1
    for i = 1, string.len(temp) do
        if string.byte(temp, i) == 44 then --44�� , ���ַ�����
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

--���������nilֵ�������ô˺��������е�Ԫ���ɴ�С��ϳ��ַ���
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

--��table�����1���򿪵Ŀ�д���ļ���
function tabletocsv(intable, csvfile)
    for i, v in pairs(intable) do
        csvfile:write(sortfieldtostr(v, ",") .. "\n")
    end
end

--��csv�ļ�����table�У������ظ�table
function csvtotable(csvfile)
    local temp = {}
    for record in csvfile:lines() do
        table.insert(temp, splitbycomma(record))
    end
    return temp
end

--�Զ���cbss.csv�ı�񰴹�����󣬲�����һ��ID����
function createcbss(t1, cbsstitle)
    local cbsstable = {}
    for i, v in pairs(t1) do
        if v[3] == "340" or v[3] == "320" then
            v[3] = "320_340"
        end
        table.insert(cbsstable, {v[1], v[3], v[4]})
        if v[1] ~= v[2] then --�����һ��ID�͵ڶ���ID����ȣ����������м�¼��
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

--��cbss���������ļ�incbssfname������淶����ļ�cbsstabfname������cbss����table
function createcbsstab(incbssfname, cbsstabfname)
    local f = openfile("cbss.csv", "r", "�Ҳ���CBSS/BSS������ϸ�ļ����뽫CBSS/BSS�����ļ�����Ϊ�� cbss.csv")
    local cbsstitle = splitbycomma(f:read("l"))
    cbsstitle[2] = cbsstitle[3]
    cbsstitle[3] = cbsstitle[4]
    cbsstitle[4] = nil
    local ctab = csvtotable(f)
    local cbsstab = createcbss(ctab, cbsstitle)
    f:close()
    f = openfile("cbsstable.csv", "w+", "�������ɹ淶��cbss�������ļ�")
    tabletocsv(cbsstab, f)
    f:close()
    return cbsstab
end

--�Զ���middle.csv�ı�������Ч�����Ч����С�
function createmid(midtab, valtab, invaltab)
    local picktab = {
        {"δ����", "�ͷ��绰", 1},
        {"δ����", "����", 2},
        {"δ����", "����", 3},
        {"δ����", "΢��", 4},
        {"δ����", "��ɨ��", 5},
        {"����", "�ͷ��绰", 6},
        {"����", "����", 7},
        {"����", "����", 8},
        {"����", "΢��", 9},
        {"����", "��ɨ��", 10},
        {"�˵�", "�ͷ��绰", 11},
        {"�˵�", "����", 12},
        {"�˵�", "����", 13},
        {"�˵�", "΢��", 14},
        {"�˵�", "��ɨ��", 15}
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
        if v[5] == "����" then
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

--���ֲ��ң��ڱ�tab�е�fieldno���ֶβ���vֵ���ҵ����ر�ĵڼ��У��Ҳ�������nil
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

--��cbsstab�в�����Ч������״̬����ÿһ�����һ���ֶκ�����һ���ֶΣ���������ҽ��10��320_340���
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

--�ҳ���cbss����״̬Ϊ10�ģ��Ҳ�����̨�����еĶ����źͿ�����롣
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

--���������ϵͳ�����ŵ���Ч������BSS/CBSS�����ȶԽ����csv�ļ�
function outval(valfname, valtab, cbsstab, midtitle)
    local f = openfile(valfname, "w+", "���ܴ�����Ч������������ļ�")
    local valt = createval(valtab, cbsstab)
    local valtitle = {}
    for i, v in pairs(midtitle) do
        valtitle[i] = v
    end
    valtitle[#valtitle + 1] = "CBSS������״̬"
    table.insert(valt, 1, valtitle)
    tabletocsv(valt, f)
    f:close()
--    f=openfile("moreper5.csv","w+","���ܴ�����CBSS������̨�������û���ϸ�ļ�")
--    tabletocsv(moreper5(valtab,cbsstab),f)
--    f:close()
end

--��ĳ����freq��Ϊ�������tab�������һ���ֶΣ�������һ���ֶβ�������sign����������sign��������signtab
function signbyfreq(signtab, tab, freq, sign)
    local temp = {}

--��һ����BUG�������ж�#tab==0������ձ�ʲôҲ����
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
        startno = (startno + freq) % (#tab) + 1  --�ڶ�����BUG��+1����Ϊȡ���ֵ��Ϊ0��ѭ������һ������
    end
end

--������Ч��������1%������ע����ÿ��100����
function signinval(invaltab)
    local signtab = {}
    for i, v in pairs(invaltab) do
        signbyfreq(signtab, v, 100, "yes")
    end
    return signtab
end

--������Ч��������ļ�csv
function outinvalid(invalfname, invaltab, midtitle)
    local f = openfile(invalfname, "w+", "���ܴ�����Ч��������ļ�")
    local signtab = signinval(invaltab)
    local invaltitle = {}
    for i, v in pairs(midtitle) do
        invaltitle[i] = v
    end
    invaltitle[#invaltitle + 1] = "�Ƿ���"
    table.insert(signtab, 1, invaltitle)
    tabletocsv(signtab, f)
    f:close()
end

--������Ч��û������ϵͳ�����ŵĶ�������1%������ע����ÿ��100����
function signvalnonum(signtab, valtab)
    signbyfreq(signtab, valtab[2], 100, "yes")
end

--����û������ϵͳ�����ŵ���Ч����csv�ļ�
function outvalnonum(valnonumfname, valtab, midtitle)
    local f = openfile(valnonumfname, "w+", "���ܴ���û������ϵͳ�����ŵ���Ч��������ļ�")
    local signtab = {}
    signvalnonum(signtab, valtab)
    local invaltitle = {}
    for i, v in pairs(midtitle) do
        invaltitle[i] = v
    end
    invaltitle[#invaltitle + 1] = "�Ƿ���"
    table.insert(signtab, 1, invaltitle)
    tabletocsv(signtab, f)
    f:close()
end

--������ʼ������̨������ϸ��BSS/CBSS������ϸ
local f = openfile("middle.csv", "r", "�Ҳ�����̨������ϸ�ļ����뽫��̨�����ļ�����Ϊ��  middle.csv")
local midtitle = splitbycomma(f:read("l"))
local midtab = csvtotable(f)
f:close()

--����̨������ϸ���ݶ�����Դ�Ͷ���״̬�ּ���Ч���������Ч������
local validtab = {{}, {}}
local invalidtab = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}
createmid(midtab, validtab, invalidtab)

--������Ч��������������������Ч�����ĳ����������csv�ļ���
outinvalid("invalid.csv", invalidtab, midtitle)
outvalnonum("valnonum.csv", validtab, midtitle)

--�������������ŵ���Ч������BSS/CBSS�����ȶԣ���ȡ��������Ӧ�������û�״̬��������ȶԽ��csv�ļ���
local cbsstab = createcbsstab("cbss.csv", "cbsstable.csv")
outval("val.csv", validtab[1], cbsstab, midtitle)

local result =
    [=[
    ִ�гɹ�����鿴
    ��Ч��������invalid.csv
    ������ϵͳ�����ŵ���Ч��������valnonum.csv
    ������ϵͳ�����ŵ���Ч������cbss/bss�����˶Խ����val.csv
]=]
print(result)

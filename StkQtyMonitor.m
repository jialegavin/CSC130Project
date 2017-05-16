function varargout = StkQtyMonitor(varargin)
% STKQTYMONITOR MATLAB code for StkQtyMonitor.fig
%      STKQTYMONITOR, by itself, creates a new STKQTYMONITOR or raises the existing
%      singleton*.
%
%      H = STKQTYMONITOR returns the handle to a new STKQTYMONITOR or the handle to
%      the existing singleton*.
%
%      STKQTYMONITOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STKQTYMONITOR.M with the given input arguments.
%
%      STKQTYMONITOR('Property','Value',...) creates a new STKQTYMONITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before StkQtyMonitor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to StkQtyMonitor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help StkQtyMonitor

% Last Modified by GUIDE v2.5 22-Jan-2016 17:33:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StkQtyMonitor_OpeningFcn, ...
                   'gui_OutputFcn',  @StkQtyMonitor_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before StkQtyMonitor is made visible.
function StkQtyMonitor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to StkQtyMonitor (see VARARGIN)
load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
%     path  = [ matlabroot '\bin\sqljdbc4.jar'];
%     javaaddpath(path)
    dbReport = database('TradeData','sa','abc@123', ...
        'com.microsoft.sqlserver.jdbc.SQLServerDriver', ...
        'jdbc:sqlserver://localhost:1433; database=TradeData');
    if ~isconnection(dbReport)
        disp([datestr(now, 'yyyy-mm-dd HH:MM:SS') ': SQL数据库连接失败']);
    else
        disp([datestr(now, 'yyyy-mm-dd HH:MM:SS') ': SQL数据库连接成功']);
    end
    dbWind = dbWindLogin();
    
%登录根网系统    
    load('..\appdata\StkAcctAll.mat');
    SysInit
    SysConnect
    for i = 1 : size(StkAcct,1)
        AcctLogin(StkAcct{i,1}, StkAcct{i,2});
        disp([StkAcct{i,1} '登陆成功'])
    end
    load('..\appdata\FutAcct.mat');
    for i = 1 : size(FutAcct,1)
        disp(['期货',FutAcct{i,1}]);  
        AcctLogin(FutAcct{i,1}, FutAcct{i,2});
    end    
    
    
    sql = ['select max(F1_1010) from TB_OBJECT_1010 WHERE F1_1010 < ''' datestr(now,'yyyymmdd') ''' '];
    lastTradeDay = fetch(dbWind,sql);
    beginDate = lastTradeDay{1,1};
    endDate = lastTradeDay{1,1};
    ReckoningLogQuery(dbReport,dbWind,beginDate,endDate);
    PositionQuery(dbReport,StkAcct);
    BonusQueryAndSendMsg(dbReport);%查询当日权益事项并发送短信
    RetradeTodayStkAndSendMsg(dbReport);%查询当日复牌股票并发送短信
    RepoBonusQueryAndSendMsg(dbReport);%鑫新雨、鑫易雨权益事项发送短信
    RepoProductIssueSendMsg(dbReport);%金自来产品发行提醒
    FuturesQueryAndSendMsg(dbReport);%查询当日是否为股指期货最后交易日
    
    handles.dbReport = dbReport;
    guidata(gcf,handles);
end
handles.timer = timer();
set(handles.timer,'ExecutionMode','fixedRate');
if strcmpi(State.ip, ip)
    set(handles.timer,'Period',60);
else
    set(handles.timer,'Period',15);
end
set(handles.timer,'TimerFcn',{@hedge_callback,handles});
set(handles.timer,'StartFcn',{@init_callback,handles});
set(handles.timer,'StopFcn',{@stop_callback,handles});

load('..\appdata\dataText.mat')
set(handles.StkQtyMonitor, 'Data', dataText);
load('..\appdata\updatedTime.mat')
set(handles.UpdatedTime,'String',updatedTime);
% Choose default command line output for StkQtyMonitor



handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes StkQtyMonitor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = StkQtyMonitor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function hedge_callback(hObject, eventdata, handles)
load('..\appdata\State.mat')
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    dbReport = handles.dbReport;
    load('..\appdata\StkAcctAll.mat');
    load('..\appdata\FutAcct.mat');
    try
        t=datevec(SysCurrentTime);  %获取交易系统当前时间
    catch e
        t=datevec(now);  %获取操作系统当前时间
    end
    if (t(1,4)==9 && t(1,5)<30)||(t(1,4)==11 && t(1,5)>30) || (t(1,4)==12)   %暂停
        
        return;
    end
    stkList = struct('exchId','0','stkId','000001');
    stkList(2) = struct('exchId','0','stkId','000300');
    stkList(3) = struct('exchId','0','stkId','000905');
    stkList(4) = struct('exchId','0','stkId','000016');
    newPriceList = StkQuotaList(stkList);
    fields = {'stkId' 'stkName' 'exchId' 'newPrice' 'knockQty' 'knockAmt'};
    names = fieldnames(newPriceList)';
    [lia locb] = ismember(fields, names);
    stocks = struct2cell(newPriceList')';  % 证券列表
    newPriceList=stocks(:,locb);
    nowTime = datestr(now,'yyyy-mm-dd HH:MM:SS.FFF');
    nowTimeList = cell(size(newPriceList,1),1);
    nowTimeList(:,1) = {nowTime};
    fields = [fields 'updateTime'];
    newPriceList = [newPriceList nowTimeList];
    insert(dbReport,'StkPriceIntraday',fields,newPriceList);
%     disp([datestr(now,'yyyy-mm-dd HH:MM:SS') '最新指数数据保存完毕'])
    
    if t(1,4)>=15 && t(1,5)>4  %非交易时间
        StkQueryKnockToday(dbReport,StkAcct); %保存当日成交数据
        PositionQuery(dbReport,FutAcct);%保存当日持仓
        FutKnockQueryToday(dbReport,FutAcct);%保存期货当日交易
        FutPositionQuery(dbReport,FutAcct);%保存期货当日持仓
        AccountAmtQuery(dbReport,StkAcct);%保存账户资金数据
       
        stop(handles.timer);
        set(handles.Start, 'Enable', 'on');
        set(handles.Stop, 'Enable', 'off');
    elseif mod(t(1,5),5)==0
        %%StkAcct = StkAcct(43,:);%读取部分账户数据
        %dbReport = SQLLogin(); %先登录SQL最后登录根网账户
        %AccountLogin(StkAcct);
        PositionQuery(dbReport,StkAcct);   %保存实时账户具体持仓
        TransactionQuery(dbReport,StkAcct);%保存实时交易汇总
        Date = datestr(now,'yyyymmdd');
        %包含了买断式回购业务的持仓，但由于根网和创新业务系统数据交互问题，股份总计字段出错，故采用的股份余额字段。
        sql = [' with StkPosition1 AS ( ' ...
        ' SELECT [date],[acctId],[stkId],[stkName],[exchId],[currentQty] '...
        ' ,case acctId when ''000000000119'' then currentQty else currentQtyForAsset end as currentQtyForAsset '...
        ' FROM StkPosition where date =  ''' Date ''' and currentQtyForAsset + currentQty  <> 0 '...
        ' ), posit as ( '...
        'select date, exchId, stkId, SUM(quantity) qty from ( '...
        '    select date, exchId, stkId, sum(currentQtyForAsset) quantity '...
        '    from StkPosition1 where date = ''' Date ''' and currentQtyForAsset <> 0 '...
        '    group by date,exchId,stkId '...
        ' ) pos '...
        ' group by date,exchId, stkId '...
        ' ), share as ( '...
        '    select F5_1090,F16_1090,OB_OBJECT_NAME_1090, F27_1084,ROW_NUMBER() over (PARTITION by F16_1090 order by F38_1084 desc) rn_share,''股票'' AS stkType '...
        '    from [10.1.3.3,10000].[wind_db].[dbo].TB_OBJECT_1084 join [10.1.3.3,10000].[wind_db].[dbo].TB_OBJECT_1090 on F1_1084=OB_REVISIONS_1090 '...
        '    where F4_1090 = ''A'' AND F38_1084 <= ''' Date ''' ), unit as ( '...
        '    select ''开放式基金'' AS F5_1090,F16_1090,OB_OBJECT_NAME_1090, CASE F100_1099 WHEN ''货币市场型'' THEN F5_1115/100 ELSE F5_1115 END AS F5_1115,ROW_NUMBER() over (PARTITION by F16_1090 order by F2_1115 desc) rn_unit,F100_1099+''基金'' AS stkType '...
        '    from [10.1.3.3,10000].[wind_db].[dbo].TB_OBJECT_1115 join [10.1.3.3,10000].[wind_db].[dbo].TB_OBJECT_1090 on F1_1115=F2_1090 '...
        '    left join [10.1.3.3,10000].[wind_db].[dbo].TB_OBJECT_1099 on F1_1115=F1_1099 '...
        '    where F2_1115 <= ''' Date ''') '... 
        ' select TOP 15  stkId,COALESCE(share.F5_1090,unit.F5_1090) as exchAbbr,COALESCE(share.OB_OBJECT_NAME_1090,unit.OB_OBJECT_NAME_1090) stkName,qty,COALESCE(COALESCE(F27_1084,F5_1115),1e6)*1e4 total,qty/COALESCE(COALESCE(F27_1084,F5_1115),1e6)/1e4 ratio,COALESCE(share.stkType,unit.stkType) as stkType '...
        ' from posit left join share on stkId = share.F16_1090 and rn_share = 1 left join unit on stkId = unit.F16_1090 and rn_unit = 1 '...
        ' where COALESCE(share.F5_1090,unit.F5_1090)  is not null  '...
        ' order by ratio desc '];
        data = fetch(dbReport,sql);
        dataText = data;
        for i =1:size(dataText,1)
            dataText{i,4} = ['<html><body color=black bgcolor=white width=97 align=right>' thousands(dataText{i,4},0) '</body></html>'];
            dataText{i,5} = ['<html><body color=black bgcolor=white width=147 align=right>' thousands(dataText{i,5},0) '</body></html>'];
            dataText{i,6} = dataText{i,6}*100;
            if strcmp(RatioStatusFcn(data{i,4},data{i,5},data{i,6},data{i,7}),'正常')
                dataText{i,6} = ['<html><body color=black bgcolor=white width=97 align=right>' num2str(dataText{i,6},'%.2f') '</body></html>'];
            elseif strcmp(RatioStatusFcn(data{i,4},data{i,5},data{i,6},data{i,7}),'警戒') %达到警戒比例
                    dataText{i,6} = ['<html><body color=black bgcolor=yellow width=97 align=right>' num2str(dataText{i,6},'%.2f') '</body></html>'];
                    message = [data{i,1} '(' dataText{i,3} ')持仓比例达到警戒水平，目前持仓比例为' num2str(data{i,6}*100,'%.2f') '%'];
                    nameList = {'梅家成','郑力铭','雷治龙','孙桃龙','郭梦柠'};
                    if t(1,4)==14 && t(1,5)>=45
                        if strcmp(data{i,1},'511660') && data{i,6}>0.15 %%建信货币基金特殊情况将限制调整为0.14
                            SendMessage(dbReport,nameList,message);
                        elseif ~strcmp(data{i,1},'511660')
                            SendMessage(dbReport,nameList,message);
                        end
                    end
            elseif strcmp(RatioStatusFcn(data{i,4},data{i,5},data{i,6},data{i,7}),'限制')%达到限制比例
                    dataText{i,6} = ['<html><body color=white bgcolor=red width=97 align=right>' num2str(dataText{i,6},'%.2f') '</body></html>'];
                    message = [data{i,1} '(' dataText{i,3} ')持仓比例达到限制水平，目前持仓比例为' num2str(data{i,6}*100,'%.2f') '%'];
                    nameList = {'梅家成','郑力铭','雷治龙','孙桃龙','郭梦柠','王皓雪'};
                   % nameList = {'梅家成'};
                   if strcmp(data{i,1},'511660') && data{i,6}>0.15 %%建信货币基金特殊情况将限制调整为0.15
                        SendMessage(dbReport,nameList,message);
                   elseif ~strcmp(data{i,1},'511660')
                        SendMessage(dbReport,nameList,message);
                   end
            end
        end
        save('..\appdata\dataText.mat','dataText');
        save('..\appdata\data.mat','data');
        updatedTime = datestr(now,'HH:MM:SS');
        save('..\appdata\updatedTime.mat','updatedTime');

        %将实时盈亏汇总数据存入SQL数据库
        sql1 = ['select MAX(updateNum) from  IntradayPnL where convert(varchar(200),date,112) = ''' Date ''' '];
        updateNum = fetch(dbReport,sql1);
        if isnan(updateNum{1,1})
            updateNum = str2num(datestr(now,'yyyymmdd'))*10000+1;
        elseif floor(updateNum{1,1}/10000) == str2num(datestr(now,'yyyymmdd'))
            updateNum = updateNum{1,1}+1;
        else
            updateNum = str2num(datestr(now,'yyyymmdd'))*10000+1;
        end
        updateNum =  num2str(updateNum);
        sql2 = [' with PnL as ( '...
        ' SELECT  [knockTime],[acctId],[stkId],[stkName],[exchId],[knockPrice],[knockQty],[knockAmt],[knockcount] '...
        '      ,[reckoningAmt],[tradingResultTypeDesc],[orderType],[regId],[updateTime],[newPrice] '...
        '      ,case tradingResultTypeDesc when ''买入成交'' then knockQty*newPrice - knockAmt  else 0 end as BuyPnL '...
        '      ,case tradingResultTypeDesc when ''卖出成交'' then knockAmt - knockQty*newPrice else 0 end as SellPnL '...
        'FROM StkDailyKnockSum '...
        'where tradingResultTypeDesc in (''买入成交'',''卖出成交'') and knockTime =  ''' Date ''' '...
        '), PnL1 as ( '...
        'select knockTime,acctId ,stkId,stkName,SUM(BuyPnL) as BuyPnl1,SUM(SellPnL) as SellPnL1 '...
        'from Pnl '...
        'group by knockTime,acctId,stkId,stkName '...
        '), PnLSum as ( '...
        'select knockTime as date,acctId,SUM(BuyPnl1) as BuyPnLSum, SUM(SellPnL1) as SellPnlSum, SUM(BuyPnl1)+SUM(SellPnL1) as PnLSum '...
        'from PnL1 '...
        'group by knockTime, acctId ) '...
        'INSERT INTO IntradayPnL '...
        'select Pl.*,Amt.stkValue,Amt.currentAmt+Amt.tradeFrozenAmt as Amt,CONVERT(varchar(200),getdate(),108) as updatedTime, ' updateNum ' as updateNum  '...
        'from PnLSum Pl join AcctDailyAmt Amt on Pl.date = Amt.date and Pl.acctId = Amt.acctId '];
        exec(dbReport,sql2);
     end
end
load('..\appdata\dataText.mat')
set(handles.StkQtyMonitor, 'Data', dataText(:,1:end-1));
load('..\appdata\updatedTime.mat')
set(handles.UpdatedTime,'String',updatedTime);

if strcmpi(State.ip, ip)
    if (t(1,4)==9 && t(1,5)>30)||(t(1,4)<=15)   %交易时间才运行 
        data2Text=FuturesRiskFcn();%20160817郭梦柠新增，用于监测期货风险度
        save('..\appdata\data2Text.mat','data2Text')
    end
end
load('..\appdata\data2Text.mat');
set(handles.FuturesRisk, 'Data', data2Text);

function ratioStatus = RatioStatusFcn(qty,total,ratio,stkType)
if strcmp(stkType,'股票') %股票风控指标
    if ratio > 0.02
        ratioStatus = '限制';
    elseif ratio>0.018
        ratioStatus = '警戒';
    else
        ratioStatus = '正常';
    end
elseif strcmp(stkType,'货币市场型基金')    %货币基金的风控指标
    if total >20000000
        if ratio >0.1 
            ratioStatus = '限制';
        elseif ratio >0.09
            ratioStatus = '警戒';
        else
            ratioStatus = '正常';
        end
    elseif ratio>0.16||qty>2000000
        ratioStatus = '限制';
    elseif ratio<0.13 && qty<1800000 
        ratioStatus = '正常';
    else
        ratioStatus = '警戒';
    end
elseif strcmp(stkType,'商品型基金')  %黄金的风控指标
    if ratio>0.16
        ratioStatus = '限制';
    elseif ratio>0.14
        ratioStatus = '警戒';
    else
        ratioStatus = '正常';
    end  
else                            %普通基金的风控指标
    if ratio>0.035
        ratioStatus = '限制';
    elseif ratio>0.03       
        ratioStatus = '警戒';
    else
        ratioStatus = '正常';
    end      
end

%20160817郭梦柠新增，用于监测期货风险度
function data2Text=FuturesRiskFcn()
%output : 2 * 4 cell with 资金账号 当日保证金占用 权益 风险度。
%pre-request: 账号已经login完成。
load('../appdata/FutAcct');  %读取所有的期货账号
currencyId = '00'; %RMB
try
    t=datevec(SysCurrentTime);  %获取交易系统当前时间
catch e
    t=datevec(now);  %获取操作系统当前时间
end
subResult = struct();
rows = size(FutAcct, 1);
dataField = cell(rows, 4);  %用来存放所有账号的资金代码，权益，当日保证金占用以及风险度
for i = 1 : rows
    subResult = FutAcctInfo(FutAcct{i, 1}, currencyId);
    dataField{i, 1} = subResult.acctId;
    dataField{i, 2} = subResult.marginUsedAmt; %当时保证金占用
    dataField{i, 3} = subResult.realtimeAmt; %权益
    dataField{i, 4} = dataField{i, 2}*100 / dataField{i, 3};  %风险度
end

%这一段是检测83和所有账户的期货风险度
% data2 = cell(2, 4);
% data2(1, :) = dataField(rows, :);
% data2{2, 1} = '衍生产品部合计';
% dataFieldOrd2 = cell2mat(dataField(1 : rows, 2));
% data2{2, 2} = sum(dataFieldOrd2);
% dataFieldOrd3 = cell2mat(dataField(1 : rows, 3));
% data2{2, 3} = sum(dataFieldOrd3);
% data2{2, 4} = data2{2, 2}*100 / data2{2, 3};

%这一段是检测83,90和所有账户的期货风险度
data2 = cell(3, 4);
data2(1, :) = dataField(rows, :);%983是最后一个账户
data2(2, :) = dataField(rows-1, :);%984账户是倒数第二个账户
data2{3, 1} = '衍生产品部合计';
dataFieldOrd2 = cell2mat(dataField(1 : rows, 2));%转化为普通格式之后才能求和
data2{3, 2} = sum(dataFieldOrd2);
dataFieldOrd3 = cell2mat(dataField(1 : rows, 3));
data2{3, 3} = sum(dataFieldOrd3);
data2{3, 4} = data2{3, 2}*100 / data2{3, 3};

dbReport = database('TradeData','sa','abc@123', ...
        'com.microsoft.sqlserver.jdbc.SQLServerDriver', ...
        'jdbc:sqlserver://localhost:1433; database=TradeData');

data2Text = data2;    
    
for i =1:size(data2,1)
    data2Text{i,2} = ['<html><body color=black bgcolor=white  align=right>' thousands(cell2mat(data2(i,2)),0) '</body></html>'];%加千分号美化
    data2Text{i,3} = ['<html><body color=black bgcolor=white  align=right>' thousands(cell2mat(data2(i,3)),0) '</body></html>'];
 
    if data2{i,4}>=90
        data2Text{i,4} = ['<html><body color=black bgcolor=red align=right>' num2str(data2{i,4},'%.2f') '</body></html>'];
        message = [data2{i,1} '期货风险度达到85%以上，目前期货风险度为' num2str(data2{i,4},'%.2f') '%，请尽快处理！'];
        nameList = {'王皓雪','陈成','郭梦柠','雷治龙'};
        SendMessage(dbReport,nameList,message);
    elseif data2{i,4}>=85
        data2Text{i,4} = ['<html><body color=black bgcolor=yellow align=right>' num2str(data2{i,4},'%.2f') '</body></html>'];
        if (t(1,4)==14 && t(1,5)>=30) && (mod(t(1,5),5)==0)
            message = [data2{i,1} '期货风险度达到警戒水平，目前期货风险度为' num2str(data2{i,4},'%.2f') '%'];
            nameList = {'王皓雪','郭梦柠'};
            SendMessage(dbReport,nameList,message);
        end
    end
end


function init_callback(hObject, eventdata, handles)



% 登出账户，断开根网工具箱连接
function stop_callback(hObject, eventdata, handles)
% load('..\appdata\State.mat');
% ip = char(java.net.InetAddress.getLocalHost());
% if strcmpi(State.ip, ip)
%     load('..\appdata\StkAcctAll.mat');
%     for i = 1 : size(StkAcct,1)
%         disp(['现货',StkAcct{i,1},'登出成功']); 
%         AcctLogout(StkAcct{i,1}, StkAcct{i,2});
%     end
%     load('..\appdata\FutAcct.mat');
%     for i = 1 : size(FutAcct,1)
%         disp(['期货',FutAcct{i,1},'登出成功']);  
%         AcctLogout(FutAcct{i,1}, FutAcct{i,2});
%     end
%     SysDisconnect
% end
% dbReport = handles.dbReport;
% close(dbReport)

% --- Executes on button press in Start.
function Start_Callback(hObject, eventdata, handles)
% hObject    handle to Start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
start(handles.timer);
set(handles.Start, 'Enable', 'off');
set(handles.Stop, 'Enable', 'on');

% --- Executes on button press in Stop.
function Stop_Callback(hObject, eventdata, handles)
% hObject    handle to Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

stop(handles.timer);
set(handles.Start, 'Enable', 'on');
set(handles.Stop, 'Enable', 'off');

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
        disp([datestr(now, 'yyyy-mm-dd HH:MM:SS') ': SQL���ݿ�����ʧ��']);
    else
        disp([datestr(now, 'yyyy-mm-dd HH:MM:SS') ': SQL���ݿ����ӳɹ�']);
    end
    dbWind = dbWindLogin();
    
%��¼����ϵͳ    
    load('..\appdata\StkAcctAll.mat');
    SysInit
    SysConnect
    for i = 1 : size(StkAcct,1)
        AcctLogin(StkAcct{i,1}, StkAcct{i,2});
        disp([StkAcct{i,1} '��½�ɹ�'])
    end
    load('..\appdata\FutAcct.mat');
    for i = 1 : size(FutAcct,1)
        disp(['�ڻ�',FutAcct{i,1}]);  
        AcctLogin(FutAcct{i,1}, FutAcct{i,2});
    end    
    
    
    sql = ['select max(F1_1010) from TB_OBJECT_1010 WHERE F1_1010 < ''' datestr(now,'yyyymmdd') ''' '];
    lastTradeDay = fetch(dbWind,sql);
    beginDate = lastTradeDay{1,1};
    endDate = lastTradeDay{1,1};
    ReckoningLogQuery(dbReport,dbWind,beginDate,endDate);
    PositionQuery(dbReport,StkAcct);
    BonusQueryAndSendMsg(dbReport);%��ѯ����Ȩ��������Ͷ���
    RetradeTodayStkAndSendMsg(dbReport);%��ѯ���ո��ƹ�Ʊ�����Ͷ���
    RepoBonusQueryAndSendMsg(dbReport);%�����ꡢ������Ȩ������Ͷ���
    RepoProductIssueSendMsg(dbReport);%��������Ʒ��������
    FuturesQueryAndSendMsg(dbReport);%��ѯ�����Ƿ�Ϊ��ָ�ڻ��������
    
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
        t=datevec(SysCurrentTime);  %��ȡ����ϵͳ��ǰʱ��
    catch e
        t=datevec(now);  %��ȡ����ϵͳ��ǰʱ��
    end
    if (t(1,4)==9 && t(1,5)<30)||(t(1,4)==11 && t(1,5)>30) || (t(1,4)==12)   %��ͣ
        
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
    stocks = struct2cell(newPriceList')';  % ֤ȯ�б�
    newPriceList=stocks(:,locb);
    nowTime = datestr(now,'yyyy-mm-dd HH:MM:SS.FFF');
    nowTimeList = cell(size(newPriceList,1),1);
    nowTimeList(:,1) = {nowTime};
    fields = [fields 'updateTime'];
    newPriceList = [newPriceList nowTimeList];
    insert(dbReport,'StkPriceIntraday',fields,newPriceList);
%     disp([datestr(now,'yyyy-mm-dd HH:MM:SS') '����ָ�����ݱ������'])
    
    if t(1,4)>=15 && t(1,5)>4  %�ǽ���ʱ��
        StkQueryKnockToday(dbReport,StkAcct); %���浱�ճɽ�����
        PositionQuery(dbReport,FutAcct);%���浱�ճֲ�
        FutKnockQueryToday(dbReport,FutAcct);%�����ڻ����ս���
        FutPositionQuery(dbReport,FutAcct);%�����ڻ����ճֲ�
        AccountAmtQuery(dbReport,StkAcct);%�����˻��ʽ�����
       
        stop(handles.timer);
        set(handles.Start, 'Enable', 'on');
        set(handles.Stop, 'Enable', 'off');
    elseif mod(t(1,5),5)==0
        %%StkAcct = StkAcct(43,:);%��ȡ�����˻�����
        %dbReport = SQLLogin(); %�ȵ�¼SQL����¼�����˻�
        %AccountLogin(StkAcct);
        PositionQuery(dbReport,StkAcct);   %����ʵʱ�˻�����ֲ�
        TransactionQuery(dbReport,StkAcct);%����ʵʱ���׻���
        Date = datestr(now,'yyyymmdd');
        %���������ʽ�ع�ҵ��ĳֲ֣������ڸ����ʹ���ҵ��ϵͳ���ݽ������⣬�ɷ��ܼ��ֶγ����ʲ��õĹɷ�����ֶΡ�
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
        '    select F5_1090,F16_1090,OB_OBJECT_NAME_1090, F27_1084,ROW_NUMBER() over (PARTITION by F16_1090 order by F38_1084 desc) rn_share,''��Ʊ'' AS stkType '...
        '    from [10.1.3.3,10000].[wind_db].[dbo].TB_OBJECT_1084 join [10.1.3.3,10000].[wind_db].[dbo].TB_OBJECT_1090 on F1_1084=OB_REVISIONS_1090 '...
        '    where F4_1090 = ''A'' AND F38_1084 <= ''' Date ''' ), unit as ( '...
        '    select ''����ʽ����'' AS F5_1090,F16_1090,OB_OBJECT_NAME_1090, CASE F100_1099 WHEN ''�����г���'' THEN F5_1115/100 ELSE F5_1115 END AS F5_1115,ROW_NUMBER() over (PARTITION by F16_1090 order by F2_1115 desc) rn_unit,F100_1099+''����'' AS stkType '...
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
            if strcmp(RatioStatusFcn(data{i,4},data{i,5},data{i,6},data{i,7}),'����')
                dataText{i,6} = ['<html><body color=black bgcolor=white width=97 align=right>' num2str(dataText{i,6},'%.2f') '</body></html>'];
            elseif strcmp(RatioStatusFcn(data{i,4},data{i,5},data{i,6},data{i,7}),'����') %�ﵽ�������
                    dataText{i,6} = ['<html><body color=black bgcolor=yellow width=97 align=right>' num2str(dataText{i,6},'%.2f') '</body></html>'];
                    message = [data{i,1} '(' dataText{i,3} ')�ֱֲ����ﵽ����ˮƽ��Ŀǰ�ֱֲ���Ϊ' num2str(data{i,6}*100,'%.2f') '%'];
                    nameList = {'÷�ҳ�','֣����','������','������','������'};
                    if t(1,4)==14 && t(1,5)>=45
                        if strcmp(data{i,1},'511660') && data{i,6}>0.15 %%���Ż��һ���������������Ƶ���Ϊ0.14
                            SendMessage(dbReport,nameList,message);
                        elseif ~strcmp(data{i,1},'511660')
                            SendMessage(dbReport,nameList,message);
                        end
                    end
            elseif strcmp(RatioStatusFcn(data{i,4},data{i,5},data{i,6},data{i,7}),'����')%�ﵽ���Ʊ���
                    dataText{i,6} = ['<html><body color=white bgcolor=red width=97 align=right>' num2str(dataText{i,6},'%.2f') '</body></html>'];
                    message = [data{i,1} '(' dataText{i,3} ')�ֱֲ����ﵽ����ˮƽ��Ŀǰ�ֱֲ���Ϊ' num2str(data{i,6}*100,'%.2f') '%'];
                    nameList = {'÷�ҳ�','֣����','������','������','������','���ѩ'};
                   % nameList = {'÷�ҳ�'};
                   if strcmp(data{i,1},'511660') && data{i,6}>0.15 %%���Ż��һ���������������Ƶ���Ϊ0.15
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

        %��ʵʱӯ���������ݴ���SQL���ݿ�
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
        '      ,case tradingResultTypeDesc when ''����ɽ�'' then knockQty*newPrice - knockAmt  else 0 end as BuyPnL '...
        '      ,case tradingResultTypeDesc when ''�����ɽ�'' then knockAmt - knockQty*newPrice else 0 end as SellPnL '...
        'FROM StkDailyKnockSum '...
        'where tradingResultTypeDesc in (''����ɽ�'',''�����ɽ�'') and knockTime =  ''' Date ''' '...
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
    if (t(1,4)==9 && t(1,5)>30)||(t(1,4)<=15)   %����ʱ������� 
        data2Text=FuturesRiskFcn();%20160817���������������ڼ���ڻ����ն�
        save('..\appdata\data2Text.mat','data2Text')
    end
end
load('..\appdata\data2Text.mat');
set(handles.FuturesRisk, 'Data', data2Text);

function ratioStatus = RatioStatusFcn(qty,total,ratio,stkType)
if strcmp(stkType,'��Ʊ') %��Ʊ���ָ��
    if ratio > 0.02
        ratioStatus = '����';
    elseif ratio>0.018
        ratioStatus = '����';
    else
        ratioStatus = '����';
    end
elseif strcmp(stkType,'�����г��ͻ���')    %���һ���ķ��ָ��
    if total >20000000
        if ratio >0.1 
            ratioStatus = '����';
        elseif ratio >0.09
            ratioStatus = '����';
        else
            ratioStatus = '����';
        end
    elseif ratio>0.16||qty>2000000
        ratioStatus = '����';
    elseif ratio<0.13 && qty<1800000 
        ratioStatus = '����';
    else
        ratioStatus = '����';
    end
elseif strcmp(stkType,'��Ʒ�ͻ���')  %�ƽ�ķ��ָ��
    if ratio>0.16
        ratioStatus = '����';
    elseif ratio>0.14
        ratioStatus = '����';
    else
        ratioStatus = '����';
    end  
else                            %��ͨ����ķ��ָ��
    if ratio>0.035
        ratioStatus = '����';
    elseif ratio>0.03       
        ratioStatus = '����';
    else
        ratioStatus = '����';
    end      
end

%20160817���������������ڼ���ڻ����ն�
function data2Text=FuturesRiskFcn()
%output : 2 * 4 cell with �ʽ��˺� ���ձ�֤��ռ�� Ȩ�� ���նȡ�
%pre-request: �˺��Ѿ�login��ɡ�
load('../appdata/FutAcct');  %��ȡ���е��ڻ��˺�
currencyId = '00'; %RMB
try
    t=datevec(SysCurrentTime);  %��ȡ����ϵͳ��ǰʱ��
catch e
    t=datevec(now);  %��ȡ����ϵͳ��ǰʱ��
end
subResult = struct();
rows = size(FutAcct, 1);
dataField = cell(rows, 4);  %������������˺ŵ��ʽ���룬Ȩ�棬���ձ�֤��ռ���Լ����ն�
for i = 1 : rows
    subResult = FutAcctInfo(FutAcct{i, 1}, currencyId);
    dataField{i, 1} = subResult.acctId;
    dataField{i, 2} = subResult.marginUsedAmt; %��ʱ��֤��ռ��
    dataField{i, 3} = subResult.realtimeAmt; %Ȩ��
    dataField{i, 4} = dataField{i, 2}*100 / dataField{i, 3};  %���ն�
end

%��һ���Ǽ��83�������˻����ڻ����ն�
% data2 = cell(2, 4);
% data2(1, :) = dataField(rows, :);
% data2{2, 1} = '������Ʒ���ϼ�';
% dataFieldOrd2 = cell2mat(dataField(1 : rows, 2));
% data2{2, 2} = sum(dataFieldOrd2);
% dataFieldOrd3 = cell2mat(dataField(1 : rows, 3));
% data2{2, 3} = sum(dataFieldOrd3);
% data2{2, 4} = data2{2, 2}*100 / data2{2, 3};

%��һ���Ǽ��83,90�������˻����ڻ����ն�
data2 = cell(3, 4);
data2(1, :) = dataField(rows, :);%983�����һ���˻�
data2(2, :) = dataField(rows-1, :);%984�˻��ǵ����ڶ����˻�
data2{3, 1} = '������Ʒ���ϼ�';
dataFieldOrd2 = cell2mat(dataField(1 : rows, 2));%ת��Ϊ��ͨ��ʽ֮��������
data2{3, 2} = sum(dataFieldOrd2);
dataFieldOrd3 = cell2mat(dataField(1 : rows, 3));
data2{3, 3} = sum(dataFieldOrd3);
data2{3, 4} = data2{3, 2}*100 / data2{3, 3};

dbReport = database('TradeData','sa','abc@123', ...
        'com.microsoft.sqlserver.jdbc.SQLServerDriver', ...
        'jdbc:sqlserver://localhost:1433; database=TradeData');

data2Text = data2;    
    
for i =1:size(data2,1)
    data2Text{i,2} = ['<html><body color=black bgcolor=white  align=right>' thousands(cell2mat(data2(i,2)),0) '</body></html>'];%��ǧ�ֺ�����
    data2Text{i,3} = ['<html><body color=black bgcolor=white  align=right>' thousands(cell2mat(data2(i,3)),0) '</body></html>'];
 
    if data2{i,4}>=90
        data2Text{i,4} = ['<html><body color=black bgcolor=red align=right>' num2str(data2{i,4},'%.2f') '</body></html>'];
        message = [data2{i,1} '�ڻ����նȴﵽ85%���ϣ�Ŀǰ�ڻ����ն�Ϊ' num2str(data2{i,4},'%.2f') '%���뾡�촦��'];
        nameList = {'���ѩ','�³�','������','������'};
        SendMessage(dbReport,nameList,message);
    elseif data2{i,4}>=85
        data2Text{i,4} = ['<html><body color=black bgcolor=yellow align=right>' num2str(data2{i,4},'%.2f') '</body></html>'];
        if (t(1,4)==14 && t(1,5)>=30) && (mod(t(1,5),5)==0)
            message = [data2{i,1} '�ڻ����նȴﵽ����ˮƽ��Ŀǰ�ڻ����ն�Ϊ' num2str(data2{i,4},'%.2f') '%'];
            nameList = {'���ѩ','������'};
            SendMessage(dbReport,nameList,message);
        end
    end
end


function init_callback(hObject, eventdata, handles)



% �ǳ��˻����Ͽ���������������
function stop_callback(hObject, eventdata, handles)
% load('..\appdata\State.mat');
% ip = char(java.net.InetAddress.getLocalHost());
% if strcmpi(State.ip, ip)
%     load('..\appdata\StkAcctAll.mat');
%     for i = 1 : size(StkAcct,1)
%         disp(['�ֻ�',StkAcct{i,1},'�ǳ��ɹ�']); 
%         AcctLogout(StkAcct{i,1}, StkAcct{i,2});
%     end
%     load('..\appdata\FutAcct.mat');
%     for i = 1 : size(FutAcct,1)
%         disp(['�ڻ�',FutAcct{i,1},'�ǳ��ɹ�']);  
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

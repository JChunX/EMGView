function varargout = GUI4(varargin)
% GUI4 MATLAB code for GUI4.fig
%      GUI4, by itself, creates a new GUI4 or raises the existing
%      singleton*.
%
%      H = GUI4 returns the handle to a new GUI4 or the handle to
%      the existing singleton*.
%
%      GUI4('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI4.M with the given input arguments.
%
%      GUI4('Property','Value',...) creates a new GUI4 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI4_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI4_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI4

% Last Modified by GUIDE v2.5 21-Feb-2020 17:21:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI4_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI4_OutputFcn, ...
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

% --- Executes just before GUI4 is made visible.
function GUI4_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI4 (see VARARGIN)
    % Initialize ui 
    set(handles.timescalemenu,'Value',7)
    set(handles.rangemenu,'Value',4);
    set(handles.refreshfrequencymenu,'Value',1);
    set(handles.viewtypemenu,'Value',1);
    set(handles.in1234button,'Value',1);
    set(handles.m1button,'Value',1);
    set(handles.m2button,'Value',1);
    set(handles.m3button,'Value',1);
    set(handles.auxbutton,'Value',1);
    set(handles.visualizestopbutton,'Visible','off');
    set(handles.recordstopbutton,'Visible','off');
    set(handles.recordbutton,'Visible','off');
    set([handles.rangemenu,handles.text7],'Visible','off');
    set([handles.timescalemenu,handles.text9],'Visible','off');
    set([handles.refreshfrequencymenu,handles.text6],'Visible','off');
    
    % Initialize GUI parameters
    handles.plotType = 'potentials';
    handles.padDimensions = [8,8];
    handles.toPlot = boolean([1,1,1,1]); % Specifies pad to plot
    handles.chPlot = true(256,1);
    handles.toRecord = boolean([1,1,1,1]); % Specifies pad to record
    handles.plotAux = 1;
    handles.multiplier = 1; % Signal scaling 
    handles.fRead = 1;  % Plot refresh frequency
    handles.recording = 0;
    handles.nCh = 256+16;
    handles.nChPlot = 256;
    handles.fSample = 2048;
    handles.dispSamples = handles.fSample; % Samples to display 
    handles.output = hObject;
    handles.recording = 0;
    handles.savepath = 0;
    handles.onlineRefreshFreq = 8; % Data read frequency when running online
    handles = graphinit(hObject,handles);
    handles.trialType = 'index_flexion'; % Default experiment type
    handles.runType = 'offLine'; 
    handles.window = 0;
    guidata(hObject, handles);

% UIWAIT makes GUI4 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%{
    graphinit 
    initializes plots
    toggles plot visibility to deafult
    creates timer object that calls update_display periodically
    starts communication with EMG machine
%}
function handles = graphinit(hObject,handles)
    handles.readSamples = handles.fSample/handles.fRead;
    %handles.readSamples = handles.fSample/64;
    handles.dispSamples = handles.readSamples;
    handles = potentialsinit(hObject,handles);
    handles = gridviewinit(hObject,handles);
    
    plotswitch(hObject,handles);
    
    handles.timer = timer(...
        'ExecutionMode','fixedRate',...
        'Period',1,...
        'TimerFcn',{@update_display,hObject});

    handles.tcpSocket = tcpip('localhost',31000);
    set(handles.tcpSocket, 'ByteOrder', 'littleEndian');
    handles.tcpSocket.InputBufferSize=handles.nCh*handles.fSample*10;
    fopen(handles.tcpSocket);
    fwrite(handles.tcpSocket,'startTX');

%{
    potenrialsinit 
    initializes potentials plot
    sets up tick
%}
function handles = potentialsinit(hObject,handles)
    nCh = handles.nChPlot;
    if handles.plotAux == 1
        nCh = nCh + 16;
    end
    
    % creates padding that adds to incoming data for visualization
    handles.padding = kron([1:nCh]',...
        ones(1,handles.dispSamples));
    
    handles.plots1 = plot(handles.axes6,0:size(handles.padding',1)-1,handles.padding');
    
    xlim(handles.axes6,[1,handles.dispSamples])
    xticks(handles.axes6,linspace(0,handles.dispSamples,11))
    ticks = mat2cell(linspace(0,round(1000*handles.dispSamples/handles.fSample),11),[1],ones(1,11));
    xticklabels(handles.axes6,ticks)
    yticks(handles.axes6,0:nCh)
    
    axis(handles.axes6,[0,handles.dispSamples,0,nCh+1])
    set(handles.axes6,'Color',[0,0,0.1])
    set(handles.axes6,'FontSize',6)
    
    guidata(hObject,handles)
   
%{
    girdviewinit 
    Initializes gridView plot
%}
function handles = gridviewinit(hObject,handles)
    handles.zerogrid = zeros((handles.nCh-16)/4,handles.readSamples);

    plotgrid(hObject,handles,handles.axes7,handles.zerogrid);
    plotgrid(hObject,handles,handles.axes8,handles.zerogrid);
    plotgrid(hObject,handles,handles.axes9,handles.zerogrid);
    plotgrid(hObject,handles,handles.axes10,handles.zerogrid);
    guidata(hObject,handles)

%{
    plotgrid
    plots incoming data as 4 8x8 arrays 
    with value as mean of sampled datapoints
%}
function gridplot = plotgrid(hObject,handles,axes,data)
    data = abs(data);
    data = mean(data,2);
    data = reshape(data,handles.padDimensions)';
    gridplot = imagesc(axes,data);
    
%{
    plotswitch
    configures GUI parameters to switch plot view
%} 
function plotswitch(hObject,handles)
    disp('switching plot')
     if strcmp(handles.plotType, 'potentials')
        set([handles.axes6;handles.axes6.Children],'visible','on')
        set([handles.axes7;handles.axes7.Children],'visible','off')
        set([handles.axes8;handles.axes8.Children],'visible','off')
        set([handles.axes9;handles.axes9.Children],'visible','off')
        set([handles.axes10;handles.axes10.Children],'visible','off')
        set([handles.edit3,handles.edit4,handles.edit5,handles.edit6,...
            handles.text11],'visible','off')
        set([handles.in1234button,handles.m1button,handles.m2button,...
            handles.m3button,handles.auxbutton,handles.text10],'visible','on')
    end
    if strcmp(handles.plotType, 'gridView')
        set([handles.axes6;handles.axes6.Children],'visible','off')
        set([handles.axes7;handles.axes7.Children],'visible','on')
        set([handles.axes8;handles.axes8.Children],'visible','on')
        set([handles.axes9;handles.axes9.Children],'visible','on')
        set([handles.axes10;handles.axes10.Children],'visible','on')
        set([handles.edit3,handles.edit4,handles.edit5,handles.edit6,...
            handles.text11],'visible','off')
        set([handles.in1234button,handles.m1button,handles.m2button,...
            handles.m3button,handles.auxbutton,handles.text10],'visible','off')
    end    
    if strcmp(handles.plotType, 'spectrogram')
        set([handles.axes6;handles.axes6.Children],'visible','off')
        set([handles.axes7;handles.axes7.Children],'visible','on')
        set([handles.axes8;handles.axes8.Children],'visible','on')
        set([handles.axes9;handles.axes9.Children],'visible','on')
        set([handles.axes10;handles.axes10.Children],'visible','on')
        set([handles.edit3,handles.edit4,handles.edit5,handles.edit6,...
            handles.text11],'visible','on')
        set([handles.in1234button,handles.m1button,handles.m2button,...
            handles.m3button,handles.auxbutton,handles.text10],'visible','off')
    end
    if strcmp(handles.plotType, 'scalogram')
        set([handles.axes6;handles.axes6.Children],'visible','off')
        set([handles.axes7;handles.axes7.Children],'visible','on')
        set([handles.axes8;handles.axes8.Children],'visible','on')
        set([handles.axes9;handles.axes9.Children],'visible','on')
        set([handles.axes10;handles.axes10.Children],'visible','on')
        set([handles.edit3,handles.edit4,handles.edit5,handles.edit6,...
            handles.text11],'visible','on')
        set([handles.in1234button,handles.m1button,handles.m2button,...
            handles.m3button,handles.auxbutton,handles.text10],'visible','off')
    end
    
function socketstop(hObject,eventdata,handles)
    delete(handles.timer)
    fwrite(handles.tcpSocket,'stopTX');
    fclose(handles.tcpSocket);
    
%{
    update_display
    runs continuously using timer
    acquires data and plots data based on current settings
%}
function update_display(hObject,eventdata,hfigure)
    t0 = clock;
    
    while etime(clock,t0) < 0.9
       
        handles = guidata(hfigure);
        % Read socket data
        handles.data = fread(handles.tcpSocket,[handles.nCh, handles.readSamples],'int16')/100; %nChxnSample

        guidata(hfigure,handles);
        % Partitions data into main and aux channels
        data = flip(handles.data(1+4:256+4,1:handles.dispSamples))';
        aux_data = [handles.data(1:4,1:handles.dispSamples);...
            handles.data(257+4:256+16,1:handles.dispSamples)];
        
        % Partitions main data into 4 pads of 64 channels
        data = {data(:,1:64);data(:,65:128);data(:,129:192);data(:,193:256)};
        
        if strcmp(handles.runType, 'realTimeControl')
            if handles.window == 0
                handles.window = handles.data;
            else
                handles.window = [handles.window,handles.data];
            end
            if toc >= 1
                handles.window = handles.window(:,handles.fSample/handles.onlineRefreshFreq+1:end);
            end
            guidata(hfigure,handles);
        end
        
        if strcmp(handles.plotType,'potentials')
            data_ = [data{handles.toPlot}]';
            %data_ = data(handles.chPlot);
            if handles.plotAux == 1
                % Combines aux and main data 
                data_ = [aux_data;data_];
            else
                data_ = data_;
            end
            
            % Scales plot and adds padding for visulization
            data_ = handles.multiplier.*data_ + handles.padding;

            for k = 1:numel(handles.plots1)
                set(handles.plots1(k),'YData',data_(k,:))
            end
        end
        
        if strcmp(handles.plotType,'gridView')
            plotgrid(hObject,handles,handles.axes7,data{1}');
            plotgrid(hObject,handles,handles.axes8,data{2}');
            plotgrid(hObject,handles,handles.axes9,data{3}');
            plotgrid(hObject,handles,handles.axes10,data{4}');
        end
        
        % Plots spectrogram using Short-Time Fourier Transform
        if strcmp(handles.plotType,'spectrogram')
            d1 = data{1}';
            d2 = data{1}';
            d3 = data{3}';
            d4 = data{4}';
            x1 = abs(spectrogram(d1(handles.sCh1,:),20));
            x2 = abs(spectrogram(d2(handles.sCh2,:),20));
            x3 = abs(spectrogram(d3(handles.sCh3,:),20));
            x4 = abs(spectrogram(d4(handles.sCh4,:),20));
            imagesc(handles.axes7,x1);
            imagesc(handles.axes8,x2);
            imagesc(handles.axes9,x3);
            imagesc(handles.axes10,x4);
        end
        
        % Plots scalogram using Continuous Wavelet Transform
        if strcmp(handles.plotType,'scalogram')
            d1 = data{1}';
            d2 = data{1}';
            d3 = data{3}';
            d4 = data{4}';
            x1 = abs(cwt(d1(handles.sCh1,:),handles.fSample));
            x2 = abs(cwt(d2(handles.sCh2,:),handles.fSample));
            x3 = abs(cwt(d3(handles.sCh3,:),handles.fSample));
            x4 = abs(cwt(d4(handles.sCh4,:),handles.fSample));
            imagesc(handles.axes7,x1);
            imagesc(handles.axes8,x2);
            imagesc(handles.axes9,x3);
            imagesc(handles.axes10,x4);

        end
        
        % Saves data into array 
        if handles.recording == 1
            disp('saving data')
            data = [data{handles.toRecord}]';
            data = [aux_data;data];
            handles.D = [handles.D, data];
            disp(size(handles.D))
            guidata(hfigure,handles);
        end
        
        pause(0.000000000000000001)
        
        t = sprintf('%.2f',toc);
        
        % Display time since visualization/record
        if handles.recording == 1
            set(handles.timebox,'string',['Rec: ',t,'s'])
        else
            set(handles.timebox,'string',[t,'s'])
        end
        pause(0.05)
        
    end

function handles = toggleChannels(hObject, eventdata, handles)

    channels = {handles.chPlot(1:64);handles.chPlot(65:128);...
                handles.chPlot(129:192);handles.chPlot(193:256)};
    channels(~handles.toPlot) = {logical(zeros(64,1))};
    channels(handles.toPlot) = {logical(ones(64,1))};
    handles.chPlot = cell2mat(channels);
    
% --- Outputs from this function are returned to the command line.
function varargout = GUI4_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in viewtypemenu.
function viewtypemenu_Callback(hObject, eventdata, handles)
% hObject    handle to viewtypemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    val = get(hObject,'Value');
    switch val
        case 1
            handles.plotType = 'potentials';
        case 2
            handles.plotType = 'gridView';
        case 3   
            handles.plotType = 'spectrogram';
        case 4
            handles.plotType = 'scalogram';
    end
    guidata(hObject,handles)
    plotswitch(hObject,handles)
% Hints: contents = cellstr(get(hObject,'String')) returns viewtypemenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from viewtypemenu


% --- Executes during object creation, after setting all properties.
function viewtypemenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to viewtypemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function timebox_Callback(hObject, eventdata, handles)
% hObject    handle to timebox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timebox as text
%        str2double(get(hObject,'String')) returns contents of timebox as a double


% --- Executes during object creation, after setting all properties.
function timebox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timebox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in in1234button.
function in1234button_Callback(hObject, eventdata, handles)
% hObject    handle to in1234button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    state = get(hObject,'Value');
    if ~(isequal(handles.toPlot,boolean([0,0,0,1])) && handles.plotAux == 0)
        pause(0.1)
        if handles.toPlot(4) == 1
            handles.toPlot(4) = 0;
        else 
            handles.toPlot(4) = 1;
        end
        
        handles = toggleChannels(hObject,eventdata,handles);
        if isfield(handles,'gridselectfigure') 
            gridselectbutton_Callback(hObject,eventdata,handles)
        end
        handles.nChPlot = sum(handles.toPlot)*64;
        handles = potentialsinit(hObject,handles);
        guidata(hObject,handles)
    else
        if state == 0
            set(handles.in1234button,'Value',1);
        end
    end
% Hint: get(hObject,'Value') returns toggle state of in1234button


% --- Executes on button press in m1button.
function m1button_Callback(hObject, eventdata, handles)
% hObject    handle to m1button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    state = get(hObject,'Value');
    if ~(isequal(handles.toPlot,boolean([0,0,1,0])) && handles.plotAux == 0)
        pause(0.1)
        if handles.toPlot(3) == 1
            handles.toPlot(3) = 0;
        else 
            handles.toPlot(3) = 1;
        end
        
        handles = toggleChannels(hObject,eventdata,handles);
        if isfield(handles,'gridselectfigure') 
            gridselectbutton_Callback(hObject,eventdata,handles)
        end
        handles.nChPlot = sum(handles.toPlot)*64;
        handles = potentialsinit(hObject,handles);
        guidata(hObject,handles)
    else
        if state == 0
            set(handles.m1button,'Value',1);
        end
    end

% Hint: get(hObject,'Value') returns toggle state of m1button


% --- Executes on button press in m3button.
function m3button_Callback(hObject, eventdata, handles)
% hObject    handle to m3button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    state = get(hObject,'Value');
    if ~(isequal(handles.toPlot,boolean([1,0,0,0])) && handles.plotAux == 0)
        pause(0.1)
        if handles.toPlot(1) == 1
            handles.toPlot(1) = 0;
        else 
            handles.toPlot(1) = 1;
        end
        
        handles = toggleChannels(hObject,eventdata,handles);
        if isfield(handles,'gridselectfigure') 
            gridselectbutton_Callback(hObject,eventdata,handles)
        end
        handles.nChPlot = sum(handles.toPlot)*64;
        handles = potentialsinit(hObject,handles);
        guidata(hObject,handles)    
    else
        if state == 0
            set(handles.m3button,'Value',1);
        end
    end

% Hint: get(hObject,'Value') returns toggle state of m3button


% --- Executes on button press in m2button.
function m2button_Callback(hObject, eventdata, handles)
% hObject    handle to m2button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    state = get(hObject,'Value');
    if ~(isequal(handles.toPlot,boolean([0,1,0,0])) && handles.plotAux == 0)
        pause(0.1)
        if handles.toPlot(2) == 1
            handles.toPlot(2) = 0;
        else 
            handles.toPlot(2) = 1;
        end
        
        handles = toggleChannels(hObject,eventdata,handles);
        if isfield(handles,'gridselectfigure') 
            gridselectbutton_Callback(hObject,eventdata,handles)
        end
        handles.nChPlot = sum(handles.toPlot)*64;
        handles = potentialsinit(hObject,handles);
        guidata(hObject,handles)
    else
        if state == 0
            set(handles.m2button,'Value',1);
        end
    end

% Hint: get(hObject,'Value') returns toggle state of m2button


% --- Executes on button press in visualizebutton.
function visualizebutton_Callback(hObject, eventdata, handles)
% hObject    handle to visualizebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles = graphinit(hObject,handles);
    guidata(hObject,handles)
    set(handles.recordbutton,'visible','on');
    set(handles.visualizebutton,'visible','off');
    set(handles.visualizestopbutton,'visible','on');
    set([handles.rangemenu,handles.text7],'Visible','on');
    set([handles.timescalemenu,handles.text9],'Visible','on');
    set([handles.refreshfrequencymenu,handles.text6],'Visible','on');
    if strcmp(get(handles.timer, 'Running'), 'off')  
        tic  
        start(handles.timer)
    end

% --- Executes on button press in recordbutton.
function recordbutton_Callback(hObject, eventdata, handles)
% hObject    handle to recordbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    if strcmp(get(handles.timer, 'Running'), 'on')
        disp('start recording')
        set([handles.visualizebutton,handles.text7],'visible','off')
        set(handles.visualizestopbutton,'visible','off')
        set(handles.recordstopbutton,'visible','on')
        set(handles.recordbutton,'visible','off')
        handles.recording = 1;
        handles.toRecord = handles.toPlot;
        handles.D = [];
        
        pad_buttons = {handles.m3button,handles.m2button,...
            handles.m1button,handles.in1234button};
        set([pad_buttons{~handles.toRecord}],'visible','off')
        guidata(hObject,handles);
    end

% --- Executes on button press in visualizestopbutton.
function visualizestopbutton_Callback(hObject, eventdata, handles)
% hObject    handle to visualizestopbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    if strcmp(get(handles.timer, 'Running'), 'on')
        set(handles.visualizebutton,'Visible','on');
        set(handles.visualizestopbutton,'Visible','off');
        set(handles.recordbutton,'Visible','off');
        set(handles.recordstopbutton,'Visible','off');
        set([handles.rangemenu,handles.text7],'Visible','off');
        set([handles.timescalemenu,handles.text9],'Visible','off');
        set([handles.refreshfrequencymenu,handles.text6],'Visible','off');
        disp('timer stop')
        t0 = clock;
        while etime(clock,t0) < 2
            stop(handles.timer)
            %set(handles.axes6,'Visible','off')
            %cla reset
        end
        socketstop(hObject,eventdata,handles)
    end

% --- Executes on button press in recordstopbutton.
function recordstopbutton_Callback(hObject, eventdata, handles)
% hObject    handle to recordstopbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(handles.timer, 'Running'), 'on') && handles.recording == 1
        set(handles.visualizestopbutton,'visible','on')
        set(handles.visualizebutton,'visible','on')
        set(handles.recordbutton,'visible','on')
        set(handles.recordstopbutton,'visible','off')
        pad_buttons = [handles.m3button,handles.m2button,...
            handles.m1button,handles.in1234button];
        set(pad_buttons,'visible','on')
        disp('stop recording')
        handles.recording = 0;
        visualizestopbutton_Callback(hObject,eventdata,handles)
        disp(size(handles.D))
        guidata(hObject,handles);
        outData = handles.D;
        fRead = handles.fRead;
        cwd = pwd;
        
        if handles.savepath == 0
            handles.savepath = uigetdir;
        end
        
        if handles.savepath ~= 0
        disp(handles.savepath)
        cd(handles.savepath)
        uisave({'outData','fRead'},handles.trialType)
        cd(cwd)
        end
    end

% --- Executes on button press in filebutton.
function filebutton_Callback(hObject, eventdata, handles)
% hObject    handle to filebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.savepath = uigetdir;
    guidata(hObject,handles)    

% --- Executes on selection change in rangemenu.
function rangemenu_Callback(hObject, eventdata, handles)
% hObject    handle to rangemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    val = get(hObject,'Value');
    switch val
        case 1
            handles.multiplier = 0.1;
        case 2
            handles.multiplier = 0.25;
        case 3   
            handles.multiplier = 0.5;
        case 4   
            handles.multiplier = 1;
        case 5   
            handles.multiplier = 2;
        case 6   
            handles.multiplier = 3;
        case 7   
            handles.multiplier = 5;
        case 8   
            handles.multiplier = 10;            
    end
    guidata(hObject,handles)
% Hints: contents = cellstr(get(hObject,'String')) returns rangemenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from rangemenu

% --- Executes during object creation, after setting all properties.
function rangemenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rangemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in timescalemenu.
function timescalemenu_Callback(hObject, eventdata, handles)
% hObject    handle to timescalemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(handles.plotType,'potentials')
        val = get(hObject,'Value');
        switch val
            case 1
                handles.dispSamples = round(10*handles.fSample/1000);
            case 2
                handles.dispSamples = round(25*handles.fSample/1000);
            case 3   
                handles.dispSamples = round(50*handles.fSample/1000);
            case 4
                handles.dispSamples = 125*handles.fSample/1000;
            case 5
                if handles.fRead < 8
                handles.dispSamples = 250*handles.fSample/1000;
                end
            case 6   
                if handles.fRead < 4
                handles.dispSamples = 500*handles.fSample/1000;
                end
            case 7
                if handles.fRead < 2
                handles.dispSamples = 1000*handles.fSample/1000; 
                end
        end
        handles = potentialsinit(hObject,handles);
        guidata(hObject,handles)
    end
% Hints: contents = cellstr(get(hObject,'String')) returns timescalemenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from timescalemenu


% --- Executes during object creation, after setting all properties.
function timescalemenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timescalemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in refreshfrequencymenu.
function refreshfrequencymenu_Callback(hObject, eventdata, handles)
% hObject    handle to refreshfrequencymenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    %if strcmp(get(handles.timer, 'Running'), 'off')
    visualizestopbutton_Callback(hObject, eventdata, handles);
        val = get(hObject,'Value');
        disp('switching fRead')
        switch val
            case 1
                handles.fRead = 1;
                set(handles.timescalemenu,'Value',7)
            case 2
                handles.fRead = 2;
                set(handles.timescalemenu,'Value',6)
            case 3
                handles.fRead = 4;
                set(handles.timescalemenu,'Value',5)
            case 4
                handles.fRead = 8;
                set(handles.timescalemenu,'Value',4)
        end
        guidata(hObject,handles)
        timescalemenu_Callback(hObject, eventdata, handles)
        
        %socketstop(hObject,eventdata,handles)
        %handles = graphinit(hObject,handles);

        guidata(hObject,handles)
    visualizebutton_Callback(hObject, eventdata, handles);
    %end
% Hints: contents = cellstr(get(hObject,'String')) returns refreshfrequencymenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refreshfrequencymenu


% --- Executes during object creation, after setting all properties.
function refreshfrequencymenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refreshfrequencymenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
    sCh1 = str2double(get(hObject,'String'));
    if (sCh1>0 && sCh1<65)
        handles.sCh1 = sCh1;
        guidata(hObject,handles)
    end

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
edit3_Callback(hObject, eventdata, handles)


function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double
    sCh2 = str2double(get(hObject,'String'));
    if (sCh2>0 && sCh2<65)
        handles.sCh2 = sCh2;
        guidata(hObject,handles)
    end

% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
edit4_Callback(hObject, eventdata, handles)


function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double
    sCh3 = str2double(get(hObject,'String'));
    if (sCh3>0 && sCh3<65)
        handles.sCh3 = sCh3;
        guidata(hObject,handles)
    end

% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
edit5_Callback(hObject, eventdata, handles)


function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double
    sCh4 = str2double(get(hObject,'String'));
    if (sCh4>0 && sCh4<65)
        handles.sCh4 = sCh4;
        guidata(hObject,handles)
    end

% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
edit6_Callback(hObject, eventdata, handles)

% --- Executes on button press in auxbutton.
function auxbutton_Callback(hObject, eventdata, handles)
% hObject    handle to auxbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    state = get(hObject,'Value');
    if isequal(handles.toPlot,boolean([0,0,0,0])) && handles.plotAux == 1
        if state == 0
            set(handles.auxbutton,'Value',1);
        end
    else

        pause(0.1)
        if handles.plotAux == 1
            handles.plotAux = 0;
        else 
            handles.plotAux = 1;
        end
    end
    
    handles = potentialsinit(hObject,handles);
    guidata(hObject,handles)    
% Hint: get(hObject,'Value') returns toggle state of auxbutton


% --- Executes on selection change in TrialType.
function TrialType_Callback(hObject, eventdata, handles)
% hObject    handle to TrialType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    val = get(hObject,'Value');
    switch val
        case 1
            handles.trialType = 'index_flexion';
        case 2
            handles.trialType = 'index_extension';
        case 3
            handles.trialType = 'middle_flex';
        case 4
            handles.trialType = 'middle_extension';
        case 5
            handles.trialType = 'pinky_flex';
        case 6
            handles.trialType = 'pinky_extension';
        case 7
            handles.trialType = 'multifinger_alternating';
    end
    
    disp(handles.trialType)
    guidata(hObject,handles)

% Hints: contents = cellstr(get(hObject,'String')) returns TrialType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TrialType

% --- Executes during object creation, after setting all properties.
function TrialType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrialType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in trainmodelbutton.
function trainmodelbutton_Callback(hObject, eventdata, handles)
% hObject    handle to trainmodelbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    state = get(hObject,'Value');
    
    if state == 1
        disp('Training Model')
        set([handles.realtimecontrolbutton,handles.offlinedecompbutton],'visible','off')
        handles.runType = 'trainModel';
    else
        set([handles.realtimecontrolbutton,handles.offlinedecompbutton],'visible','on')
        handles.runType = 'visualization';
    end
    
    guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of trainmodelbutton


% --- Executes on button press in realtimecontrolbutton.
function realtimecontrolbutton_Callback(hObject, eventdata, handles)
% hObject    handle to realtimecontrolbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    state = get(hObject,'Value');
    
    if state == 1
        disp('Real Time Control')
        set([handles.trainmodelbutton,handles.offlinedecompbutton],'visible','off')
        handles.runType = 'realTimeControl';
    else
        set([handles.trainmodelbutton,handles.offlinedecompbutton],'visible','on')
        handles.runType = 'visualization';
    end
    
    guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of realtimecontrolbutton


% --- Executes on button press in offlinedecompbutton.
function offlinedecompbutton_Callback(hObject, eventdata, handles)
% hObject    handle to offlinedecompbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    state = get(hObject,'Value');

    if state == 1
        disp('Offline Decomposition')
        set([handles.realtimecontrolbutton,handles.trainmodelbutton],'visible','off')
        handles.runType = 'offLineDecomp';
    else
        set([handles.realtimecontrolbutton,handles.trainmodelbutton],'visible','on')
        handles.runType = 'visualization';
    end
    
    guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of offlinedecompbutton


% --- Executes on button press in gridselectbutton.
function gridselectbutton_Callback(hObject, eventdata, handles)
% hObject    handle to gridselectbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        % Create figure for selecting channel view on grid
    if ~isfield(handles,'gridselectfigure') 
        handles.gridselectfigure = figure('Name','Select Channels to Plot','NumberTitle','off');
    end
    % Create 1 uipanel per EMG pad
    p1 = uipanel(handles.gridselectfigure,'Position',[0.5,0,0.5,0.45]);
    p2 = uipanel(handles.gridselectfigure,'Position',[0,0,0.5,0.45]);
    p3 = uipanel(handles.gridselectfigure,'Position',[0.5,0.45,0.5,0.45]);  
    p4 = uipanel(handles.gridselectfigure,'Position',[0,0.45,0.5,0.45]);
    pt = uipanel(handles.gridselectfigure,'Position',[0,0.9,1,0.1]);
    
    pos  = [0, 0, 0.1, 0.1];  % [X, Y, Width, Height]
    button_group = cell(handles.nCh-16,1);  
   
    ch = 1;
    
    inverse_button = uicontrol(pt,'Style','PushButton',...
                                'Units','Normalized','Position',[0,0.5,0.2,0.5],...
                                'String','Toggle All',...
                                'Callback',{@gridselect_Callback,handles});
    
    % Create buttons for each pad
    for i1 = 1:8
      pos(2) = 0.1*i1;

      for i2 = 1:8
        pos(1) = 0.1*i2;

        button_group{ch} = uicontrol(p1,'Style', 'ToggleButton', ...
                                   'Units', 'Normalized', 'Position', pos,...
                                   'String',ch,...
                                   'Callback',{@gridselect_Callback,handles});
        ch = ch + 1;
      end
    end
    
        
    for i1 = 1:8
      pos(2) = 0.1*i1;

      for i2 = 1:8
        pos(1) = 0.1*i2;

        button_group{ch} = uicontrol(p2,'Style', 'ToggleButton', ...
                                   'Units', 'Normalized', 'Position', pos,...
                                   'String',ch,...
                                   'Callback',{@gridselect_Callback,handles});
        ch = ch + 1;
      end
    end
    
        
    for i1 = 1:8
      pos(2) = 0.1*i1;

      for i2 = 1:8
        pos(1) = 0.1*i2;

        button_group{ch} = uicontrol(p3,'Style', 'ToggleButton', ...
                                   'Units', 'Normalized', 'Position', pos,...
                                   'String',ch,...
                                   'Callback',{@gridselect_Callback,handles});   
        ch = ch + 1;
      end
    end
    
        
    for i1 = 1:8
      pos(2) = 0.1*i1;

      for i2 = 1:8
        pos(1) = 0.1*i2;

        button_group{ch} = uicontrol(p4,'Style', 'ToggleButton', ...
                                   'Units', 'Normalized', 'Position', pos,...
                                   'String',ch,...
                                   'Callback',{@gridselect_Callback,handles});     
        ch = ch + 1;
      end
    end

    for ch = 1:handles.nCh-16
        % Presses button down if already displaying channel                       
        if handles.chPlot(ch)
            set(button_group{ch},'Value',true)
        else
            set(button_group{ch},'Value',false)
        end
    end
     
    guidata(hObject,handles)

function gridselect_Callback(hObject,eventdata,handles)
    % Adjust chPlot based on button presses
    
    arg = get(hObject,'String');
    
    if ~(isempty(str2num(arg)))
        ch = str2num(arg);

        if handles.chPlot(ch)
            handles.chPlot(ch) = 0;
        else
            handles.chPlot(ch) = 1;
        end
    end
        
    if (strcmp(arg,'Toggle All'))
        nPlotting = size(find(handles.chPlot == 1));
        nPlotting = nPlotting(1);
        if  nPlotting > handles.nChPlot/2
            handles.chPlot(:) = 0; 
            if handles.plotAux == 0
                set(handles.auxbutton,'Value',1)
                auxbutton_Callback(hObject,eventdata,handles)
            end
        else
            handles.chPlot(:) = 1;
        end
    end

    guidata(handles.gridselectfigure,handles)
    gridselectbutton_Callback(hObject,eventdata,handles)

    
        
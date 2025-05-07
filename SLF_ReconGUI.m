%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3D Reconstruction code for squeezed light field microscopy (SLIM) using Richardson-Lucy Deconvolution
%%
%% Kilohertz volumetric imaging of in-vivo dynamics using squeezed light field microscopy
%% Authors: Wang, Zhaoqiang, Ruixuan Zhao, Daniel A. Wagenaar, Diego Espino, Liron Sheintuch, Ohr Benshlomo, Wenjun Kang et al. 
%% Affiliation: University of California, Los Angeles; California Institute of Technology; University of Arizona  
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function varargout = SLF_ReconGUI(varargin)
% SLF_RECONGUI MATLAB code for SLF_ReconGUI.fig
%      SLF_RECONGUI, by itself, creates a new SLF_RECONGUI or raises the existing
%      singleton*.
%
%      H = SLF_RECONGUI returns the handle to a new SLF_RECONGUI or the handle to
%      the existing singleton*.
%
%      SLF_RECONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SLF_RECONGUI.M with the given input arguments.
%
%      SLF_RECONGUI('Property','Value',...) creates a new SLF_RECONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SLF_ReconGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SLF_ReconGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SLF_ReconGUI

% Last Modified by GUIDE v2.5 05-May-2025 12:49:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SLF_ReconGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SLF_ReconGUI_OutputFcn, ...
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

% --- Executes just before SLF_ReconGUI is made visible.
function SLF_ReconGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SLF_ReconGUI (see VARARGIN)

% Choose default command line output for SLF_ReconGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SLF_ReconGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

global config_struct;
if ~exist('./RUN', 'dir')
    mkdir('./RUN');
end
config_file = './RUN/last_config_gpu.json';
if exist(config_file)
    fid = fopen(config_file, 'r');
    if fid>=3
        config_struct = jsondecode(fscanf(fid, '%s'));
    else
        error('Invalid path for configuration file.');
    end  
    try
        set(handles.filepath,'String',config_struct.filePath);
        set(handles.psfpath,'String',config_struct.psfPath);
        set(handles.loadexistingpsf,'Value',config_struct.loadExistingPSF);
        set(handles.scaleratio,'String',num2str(config_struct.scaleRatio));
        set(handles.resolution,'String',num2str(config_struct.RESOLUTION));
        set(handles.psfbg,'String',num2str(config_struct.PSF_background));
        set(handles.databg,'String',num2str(config_struct.background));
        set(handles.iter,'String',num2str(config_struct.iter));
        set(handles.intensityscale,'String',num2str(config_struct.intensityScale));
        set(handles.usinggpu,'Value',config_struct.usingGPU);
        if strcmp(config_struct.conv_type,'fft')
            set(handles.convmenu,'Value',1);
        elseif strcmp(config_struct.conv_type,'simple_fft')
            set(handles.convmenu,'Value',2);
        elseif strcmp(config_struct.conv_type,'space_domain')
            set(handles.convmenu,'Value',3);
        else
            error('Invalid conv type.');
        end
        set(handles.numviews,'String',num2str(config_struct.numViews));
        set(handles.uitable, 'Data', [config_struct.angles,config_struct.ROIpositions]);        
        set(handles.datapath, 'String', config_struct.dataPath);
        
        set(handles.psfz1, 'String', num2str(config_struct.psfZ1));
        set(handles.psfz2, 'String', num2str(config_struct.psfZ2));
        set(handles.psfstep, 'String', num2str(config_struct.psfZStep));
        set(handles.psfnameformat, 'String', config_struct.psfFormat);
        set(handles.datat1, 'String', num2str(config_struct.dataT1));
        set(handles.datat2, 'String', num2str(config_struct.dataT2));
        set(handles.datanameformat, 'String', config_struct.dataFormat);
    
    catch ME
        if strcmp(ME.identifier, 'MATLAB:nonExistentField')
            variable_name = split(ME.message, '"');
            error(['Invalid configuration file with missing variable: ' variable_name{2}]);
        else
            throw(ME);
        end
    end
else
    set(handles.filepath,'String','./examples/beads');
    set(handles.psfpath,'String','PSF_320');
    set(handles.loadexistingpsf,'Value',1);
    set(handles.scaleratio,'String',num2str(0.2));
    set(handles.resolution,'String',num2str(305));
    set(handles.psfbg,'String',num2str(200));
    set(handles.databg,'String',num2str(1500));
    set(handles.iter,'String',num2str(16));
    set(handles.intensityscale,'String',num2str(0.1));
    set(handles.usinggpu,'Value',1);
    set(handles.convmenu,'Value',2);
    
    set(handles.numviews,'String',num2str(29));
    angles = 2*[-25.85;-35;-43.65;32.18;23.57;-9.75;-19.2;-37.85;35.66;13.295;7.74;-3.65;-6.15;-41;41.9;38.795;4.405;0.905;9.915;16.35;26.125;-28.28;-15.3;-11.955;19.405;28.85;-47.5;-31.4;-20.85];
    ROIpositions = [956,31;1300,34;1660,33;1940,33;2294,33;760,98;1110,98;1464,96;1778,98;2125,95;2475,96;584,159;929,159;1285,158;1620,162;1972,163;2301,156;2648,156;753,221;1099,220;1454,224;1788,218;2129,219;2479,213;938,288;1281,285;1604,281;1991,266;2295,281];
    set(handles.uitable, 'Data', [angles,ROIpositions]);  
    clear angles ROIpositions

    set(handles.datapath, 'String', 'data/beads_100ms_ROI_1455_320_LED');
    
    set(handles.psfz1, 'String', num2str(-200));
    set(handles.psfz2, 'String', num2str(200));
    set(handles.psfstep, 'String', num2str(4));
    set(handles.psfnameformat, 'String', '%d.tiff.tif');
    set(handles.datat1, 'String', num2str(1));
    set(handles.datat2, 'String', num2str(1));
    set(handles.datanameformat, 'String', 'ss_single_%d.tiff');
end
drawViews(handles);

% --- Outputs from this function are returned to the command line.
function varargout = SLF_ReconGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function filepath_Callback(hObject, eventdata, handles)
% hObject    handle to filepath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filepath as text
%        str2double(get(hObject,'String')) returns contents of filepath as a double


% --- Executes during object creation, after setting all properties.
function filepath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filepath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function psfpath_Callback(hObject, eventdata, handles)
% hObject    handle to psfpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of psfpath as text
%        str2double(get(hObject,'String')) returns contents of psfpath as a double


% --- Executes during object creation, after setting all properties.
function psfpath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to psfpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function psfz1_Callback(hObject, eventdata, handles)
% hObject    handle to psfz1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of psfz1 as text
%        str2double(get(hObject,'String')) returns contents of psfz1 as a double


% --- Executes during object creation, after setting all properties.
function psfz1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to psfz1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function psfstep_Callback(hObject, eventdata, handles)
% hObject    handle to psfstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of psfstep as text
%        str2double(get(hObject,'String')) returns contents of psfstep as a double


% --- Executes during object creation, after setting all properties.
function psfstep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to psfstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function psfz2_Callback(hObject, eventdata, handles)
% hObject    handle to psfz2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of psfz2 as text
%        str2double(get(hObject,'String')) returns contents of psfz2 as a double


% --- Executes during object creation, after setting all properties.
function psfz2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to psfz2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function psfnameformat_Callback(hObject, eventdata, handles)
% hObject    handle to psfnameformat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of psfnameformat as text
%        str2double(get(hObject,'String')) returns contents of psfnameformat as a double


% --- Executes during object creation, after setting all properties.
function psfnameformat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to psfnameformat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in loadexistingpsf.
function loadexistingpsf_Callback(hObject, eventdata, handles)
% hObject    handle to loadexistingpsf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of loadexistingpsf



function scaleratio_Callback(hObject, eventdata, handles)
% hObject    handle to scaleratio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scaleratio as text
%        str2double(get(hObject,'String')) returns contents of scaleratio as a double


% --- Executes during object creation, after setting all properties.
function scaleratio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scaleratio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function resolution_Callback(hObject, eventdata, handles)
% hObject    handle to resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of resolution as text
%        str2double(get(hObject,'String')) returns contents of resolution as a double


% --- Executes during object creation, after setting all properties.
function resolution_CreateFcn(hObject, eventdata, handles)
% hObject    handle to resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function psfbg_Callback(hObject, eventdata, handles)
% hObject    handle to psfbg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of psfbg as text
%        str2double(get(hObject,'String')) returns contents of psfbg as a double


% --- Executes during object creation, after setting all properties.
function psfbg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to psfbg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when entered data in editable cell(s) in uitable.
function uitable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% plot(handles.axes1, rand(5,5)); hold on;
% plot(handles.axes1, 5,5,'ro'); 
% disp(eventdata.NewData);
drawViews(handles)



function iter_Callback(hObject, eventdata, handles)
% hObject    handle to iter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iter as text
%        str2double(get(hObject,'String')) returns contents of iter as a double


% --- Executes during object creation, after setting all properties.
function iter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in convmenu.
function convmenu_Callback(hObject, eventdata, handles)
% hObject    handle to convmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns convmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from convmenu


% --- Executes during object creation, after setting all properties.
function convmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to convmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in usinggpu.
function usinggpu_Callback(hObject, eventdata, handles)
% hObject    handle to usinggpu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of usinggpu



function databg_Callback(hObject, eventdata, handles)
% hObject    handle to databg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of databg as text
%        str2double(get(hObject,'String')) returns contents of databg as a double


% --- Executes during object creation, after setting all properties.
function databg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to databg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function datapath_Callback(hObject, eventdata, handles)
% hObject    handle to datapath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of datapath as text
%        str2double(get(hObject,'String')) returns contents of datapath as a double


% --- Executes during object creation, after setting all properties.
function datapath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to datapath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function datat1_Callback(hObject, eventdata, handles)
% hObject    handle to datat1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of datat1 as text
%        str2double(get(hObject,'String')) returns contents of datat1 as a double


% --- Executes during object creation, after setting all properties.
function datat1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to datat1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function datat2_Callback(hObject, eventdata, handles)
% hObject    handle to datat2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of datat2 as text
%        str2double(get(hObject,'String')) returns contents of datat2 as a double


% --- Executes during object creation, after setting all properties.
function datat2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to datat2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit16_Callback(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit16 as text
%        str2double(get(hObject,'String')) returns contents of edit16 as a double


% --- Executes during object creation, after setting all properties.
function edit16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function datanameformat_Callback(hObject, eventdata, handles)
% hObject    handle to datanameformat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of datanameformat as text
%        str2double(get(hObject,'String')) returns contents of datanameformat as a double


% --- Executes during object creation, after setting all properties.
function datanameformat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to datanameformat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in reconstruct.
function reconstruct_Callback(hObject, eventdata, handles)
% hObject    handle to reconstruct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addpath('wrapper/','utils/');
global config_struct;
config_struct.filePath = get(handles.filepath,'String');
config_struct.psfPath = get(handles.psfpath,'String');
config_struct.loadExistingPSF = get(handles.loadexistingpsf,'Value');
config_struct.scaleRatio = str2double(get(handles.scaleratio,'String'));
config_struct.RESOLUTION = str2double(get(handles.resolution,'String'));
config_struct.PSF_background = str2double(get(handles.psfbg,'String'));
config_struct.background = str2double(get(handles.databg,'String'));
config_struct.iter = str2double(get(handles.iter,'String'));
config_struct.intensityScale = str2double(get(handles.intensityscale,'String'));
config_struct.usingGPU = get(handles.usinggpu,'Value');
if get(handles.convmenu,'Value')==1
    config_struct.conv_type = 'fft';
elseif get(handles.convmenu,'Value')==2
    config_struct.conv_type = 'simple_fft';
elseif get(handles.convmenu,'Value')==3
    config_struct.conv_type = 'space_domain';
else
    error('Invalid conv type.');
end

config_struct.numViews = str2double(get(handles.numviews,'String'));
temp = get(handles.uitable, 'Data');
config_struct.angles = temp(:,1);
config_struct.ROIpositions = temp(:,2:3);

config_struct.dataPath = get(handles.datapath,'String');

config_struct.psfZ1 = str2double(get(handles.psfz1,'String'));
config_struct.psfZ2 = str2double(get(handles.psfz2,'String'));
config_struct.psfZStep = str2double(get(handles.psfstep,'String'));
config_struct.psfFormat = get(handles.psfnameformat,'String');

config_struct.dataT1 = str2double(get(handles.datat1,'String'));
config_struct.dataT2 = str2double(get(handles.datat2,'String'));
config_struct.dataFormat = get(handles.datanameformat,'String');

psfName = {};
psfLocations = config_struct.psfZ1:config_struct.psfZStep:config_struct.psfZ2; 
for p = 1:length(psfLocations)
    psfName{p}=sprintf(config_struct.psfFormat, psfLocations(p));
end
config_struct.psfName = psfName;

dataName = {};
saveName = {};
ind=1;
for d = config_struct.dataT1:config_struct.dataT2  
    tmpName = sprintf(config_struct.dataFormat,d);
    dataName{ind}=tmpName;
    tmpNameS = split(tmpName,'.'); 
    saveName{ind}=tmpNameS{1};
    ind = ind + 1;
end
config_struct.dataName = dataName;
config_struct.saveName = saveName;
config_struct.savePath = 'Recon_RL';

jsonText = jsonencode(config_struct,"PrettyPrint",true);
fid = fopen(fullfile('./RUN','last_config_gpu.json'), 'w');
fprintf(fid, '%s', jsonText);
fclose(fid);

disp('Reconstructing...');
SLF_Recon_Wrapper(config_struct, false, true);


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in calibrate.
function calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
addpath('utils/');
disp('Semi-auto sub-aperture center calibration...');
disp('Choose a PSF image at native focal plane to calibrate view centers.');
[file_name, file_path] = uigetfile({'*.tif','*.tiff'}, 'Choose a PSF image at native focal plane to calibrate view centers.');
img = imread(fullfile(file_path,file_name));
scale_ratio = str2double(get(handles.scaleratio, 'String'));
resolution = str2double(get(handles.resolution, 'String'));
num_roi = str2double(get(handles.numviews, 'String'));
temp = get(handles.uitable,'Data');
angles = temp(:,1);

h = msgbox('Follow the instructions in command line.');
disp('------------------------------------------------------');
usrinput1 = str2num(input('What is the arrangement of views, i.e. number of views per row, from up to down? \n Type numbers separated by comma(,) or space:    ', 's'));
while sum(usrinput1)~=num_roi
    disp('------------------------------------------------------');
    disp('The input arrangment does not add up to the total number of views. Please try agagin.');
    usrinput1 = str2num(input('What is the arrangement of views, i.e. number of views per row, from up to down? \n Type numbers separated by comma(,) or space:    ', 's'));
end
disp('------------------------------------------------------');
usrinput2 = str2num(input('What is the background of the selected image? Type a scalar number:    ', 's'));
ROIpositions = calibration_semiauto_func(img, scale_ratio, resolution, num_roi, usrinput1, angles, usrinput2);
set(handles.uitable, 'Data', [angles ROIpositions]);
save(fullfile(file_path, 'Calibration.mat'), 'ROIpositions');
drawViews(handles);
close(h);
     


% --- Executes on button press in loadcalibration.
function loadcalibration_Callback(hObject, eventdata, handles)
% hObject    handle to loadcalibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Load subaperture center positions');
disp('Choose subaperture position calibration mat file.');
[file_name, file_path] = uigetfile('*.mat', 'Choose subaperture position calibration mat file.');
load(fullfile(file_path, file_name));
temp1 = get(handles.uitable,'Data');
angles = temp1(:,1);
if length(angles) <= size(ROIpositions,1)
    temp2 = zeros(size(ROIpositions,1),3);
    temp2(1:length(angles),1) = angles;
    temp2(:,2:3) = ROIpositions;
else
    temp2 = temp1(1:size(ROIpositions,1),:);
    temp2(:,2:3) = ROIpositions;
end
set(handles.uitable, 'Data', temp2);
set(handles.numviews, 'String', num2str(size(temp2,1)));
drawViews(handles);



% --- Executes on button press in loadconfigs.
function loadconfigs_Callback(hObject, eventdata, handles)
% hObject    handle to loadconfigs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global config_struct;

disp('Load configurations from json files.');
disp('Choose a json file to load configurations.');
[file_name, file_path] = uigetfile('*.json', 'Choose a json file to load configurations.');
fid = fopen(fullfile(file_path, file_name), 'r');
if fid>=3
    config_struct = jsondecode(fscanf(fid, '%s'));
else
    error('Invalid path for configuration file.');
end

try
    set(handles.filepath,'String',config_struct.filePath);
    set(handles.psfpath,'String',config_struct.psfPath);
    set(handles.loadexistingpsf,'Value',config_struct.loadExistingPSF);
    set(handles.scaleratio,'String',num2str(config_struct.scaleRatio));
    set(handles.resolution,'String',num2str(config_struct.RESOLUTION));
    set(handles.psfbg,'String',num2str(config_struct.PSF_background));
    set(handles.databg,'String',num2str(config_struct.background));
    set(handles.iter,'String',num2str(config_struct.iter));
    set(handles.intensityscale,'String',num2str(config_struct.intensityScale));
    set(handles.usinggpu,'Value',config_struct.usingGPU);
    if strcmp(config_struct.conv_type,'fft')
        set(handles.convmenu,'Value',1);
    elseif strcmp(config_struct.conv_type,'simple_fft')
        set(handles.convmenu,'Value',2);
    elseif strcmp(config_struct.conv_type,'space_domain')
        set(handles.convmenu,'Value',3);
    else
        error('Invalid conv type.');
    end        
    set(handles.numviews, 'String', num2str(config_struct.numViews));
    set(handles.uitable, 'Data', [config_struct.angles,config_struct.ROIpositions]);        
    set(handles.datapath, 'String', config_struct.dataPath);
    
    set(handles.psfz1, 'String', num2str(config_struct.psfZ1));
    set(handles.psfz2, 'String', num2str(config_struct.psfZ2));
    set(handles.psfstep, 'String', num2str(config_struct.psfZStep));
    set(handles.psfnameformat, 'String', config_struct.psfFormat);
    set(handles.datat1, 'String', num2str(config_struct.dataT1));
    set(handles.datat2, 'String', num2str(config_struct.dataT2));
    set(handles.datanameformat, 'String', config_struct.dataFormat);

catch ME
    if strcmp(ME.identifier, 'MATLAB:nonExistentField')
        variable_name = split(ME.message, '"');
        error(['Invalid configuration file with missing variable: ' variable_name{2}]);
    else
        throw(ME);
    end
end

% --- Executes during object creation, after setting all properties.
function loadconfigs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loadconfigs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function intensityscale_Callback(hObject, eventdata, handles)
% hObject    handle to intensityscale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of intensityscale as text
%        str2double(get(hObject,'String')) returns contents of intensityscale as a double


% --- Executes during object creation, after setting all properties.
function intensityscale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to intensityscale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1



function drawViews(handles)
    
    temp = get(handles.uitable,'Data');
    angles = temp(:,1);
    ROIpositions = temp(:,2:3);
    RESOLUTION = str2double(get(handles.resolution,'String'));
    scaleRatio = str2double(get(handles.scaleratio,'String'));
    cla(handles.axes1,'reset');
    axes(handles.axes1);
    for i=1:length(angles)
        r1 = ROIpositions(i,2) + ceil(-RESOLUTION*scaleRatio/2);
        r2 = ROIpositions(i,2) + ceil(RESOLUTION*scaleRatio/2) - 1;
        c1 = ROIpositions(i,1) + ceil(-RESOLUTION/2);
        c2 = ROIpositions(i,1) + ceil(RESOLUTION/2) - 1;
        rectangle('Position',[c1 r1 RESOLUTION round(RESOLUTION*scaleRatio)], 'EdgeColor','r');hold on;    
    end
    hold off;
    axis equal tight



function numviews_Callback(hObject, eventdata, handles)
% hObject    handle to numviews (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numviews as text
%        str2double(get(hObject,'String')) returns contents of numviews as a double
numviews = str2double(get(hObject,'String'));
temp1 = get(handles.uitable,'Data');
if numviews <= size(temp1,1)
    temp2 = temp1(1:numviews,:);
else
    temp2 = zeros(numviews,3);
    temp2(1:size(temp1,1),:) = temp1;
end
set(handles.uitable,'Data',temp2);
drawViews(handles)




% --- Executes during object creation, after setting all properties.
function numviews_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numviews (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

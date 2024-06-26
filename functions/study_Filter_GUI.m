function h = study_Filter_GUI(study, filenames)

scheme = eeg_LoadScheme;
scrsize = get(0, 'ScreenSize');
Wdth = 550; Hght = 200;
Bttn_HalfWidth = 12;
Bttn_HalfHeight = 18;
LBHeight = Hght * .95;

%setup the main figure window
handles.figure = uifigure;
h = handles.figure;

set(handles.figure,...
    'Color', scheme.Window.BackgroundColor.Value, ...
    'Name', 'Data Filtering',...
    'NumberTitle', 'off',...
    'Position', [(scrsize(3)-Wdth)/2,(scrsize(4)-Hght)/2,Wdth,Hght],...
    'Resize', 'off',...
    'menubar', 'none',...
    'WindowStyle', 'modal');

%*************************************************************************
handles.edit_lowfilt = uieditfield(handles.figure, ...
    'numeric',...
    'Value', 1.0,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value, ...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'Position', [130, 165, 100, 20]);

handles.edit_highfilt = uieditfield(handles.figure, ...
    'numeric',...
    'Value', 50,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value, ...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'Position', [130, 125, 100, 20]);

uilabel('Parent', handles.figure, ...
    'Text', sprintf('Low edge (Hz)'),...
    'HorizontalAlignment', 'left', ...
    'Position', [20, 165, 100, 20], ...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

uilabel('Parent', handles.figure, ...
    'Text', sprintf('High edge (Hz)'),...
    'HorizontalAlignment', 'left', ...
    'Position', [20, 125, 100, 20],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

handles.check_overwrite = uicheckbox(...
    'Parent', handles.figure,...
    'Value', 0,...
    'Text', 'Overwrite input files',...
    'Position', [130, 60, 150, 20],...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);

bwidth = 100;
handles.button_filter = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Filter',...
    'Position', [Wdth-bwidth-10, 5, bwidth, scheme.Button.Height.Value],...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

handles.button_cancel = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Cancel',...
    'Position', [Wdth-(bwidth*2)-20, 5, bwidth, scheme.Button.Height.Value],...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'ButtonPushedFcn', {@callback_close});

handles.bgroup = uibuttongroup(...
    'Parent', handles.figure,...
    'Position',[300 60 220 125],...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value);   

handles.radio_bandpass = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Position', [10, 100, 150, 20], ...
    'Value', 1,...
    'Text', 'Band pass filter',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);

handles.radio_highpass = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Position', [10, 70, 150, 20], ...
    'Value', 0,...
    'Text', 'High Pass filter',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);


handles.radio_lowpass = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Position', [10, 40, 150, 20], ...
    'Value', 0,...
    'Text', 'Low pass filter',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);


handles.radio_notch = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Position', [10, 10, 150, 20], ...
    'Value', 0,...
    'Text', 'Band stop filter',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);

handles.button_filter.ButtonPushedFcn = {@callback_filter, handles, filenames, study};


%**************************************************************************
function callback_close(hObject, eventdata)
closereq();


%**********************************************
function callback_filter(hObject, eventdata, h, filenames, study)

    %extension to add to the output file
    file_id = '_filt';
    start = clock;
    %for outputing record keeping information
    Parameters.operation = {'Operation', 'filter'};
    Parameters.date = {'Date and time', datetime("now")};
    tic;

    if  h.radio_lowpass.Value == 1
        ledge = 0;
    else
        ledge = h.edit_lowfilt.Value;
    end
    
    if h.radio_highpass.Value == 1
        hedge = 0;
    else
        hedge = h.edit_highfilt.Value;
    end
    
    
    if (ledge > 0) && (hedge > 0) 
        if ledge >= hedge
        msgbox('Low edge cannot exceed high edge range')
        return
        end
    end

    Parameters.lowedge = {'Low cutoff', ledge};
    Parameters.highedge = {'High cutoff', hedge};
    Parameters.function = {'Function', 'pop_eegfiltnew'};

    revfilt = h.radio_notch.Value;
    owrite = h.check_overwrite.Value;
    
    try    
    %set a progress bar
    pbar = uiprogressdlg(h.figure,...
        'Title', 'filtering in progress',...
        'ShowPercentage', 'on');
   
    option = 0;
    nfile = length(filenames);
    reportValues = cell(size(filenames));
       
        for jj = 1:nfile
            [path, file, ext] = fileparts(filenames{jj});
            if owrite
                outfilename = file;
            else
                [file_id, option,writeflag] = wwu_verifySaveFile(path, file, file_id, ext, option);
                if option == 3 && ~writeflag
                    fprintf('skipping existing file...\n')
                    reportValues{jj} = 'not saved';
                    continue;
                else
                    outfilename = [file, file_id];
                    reportValues{jj} = outfilename;
                end
            end
            
            EEGIn = wwu_LoadEEGFile(filenames{jj});
            fprintf('Filtering the data\n');
            
            fprintf('lowcutoff %f, highcutoff %f, revfilt %f\n', ledge, hedge, revfilt)
            EEGIn = pop_eegfiltnew( EEGIn, 'locutoff', ledge, 'hicutoff', hedge, 'revfilt', revfilt);
            newfile = fullfile(path, [outfilename, ext]);
            wwu_SaveEEGFile(EEGIn, newfile);
        
            pbar.Value  = jj/nfile;
    
        end
        
        clear EEGIn
        close(pbar)
   
        Parameters.elapsedtime = {'Elapsed Time (s)', toc}; 
        wwu_UpdateProcessLog(study, 'RowNames', filenames, 'ColumnNames', {'Output file'}, 'Values',reportValues', 'SheetName','filter', 'Parameters', Parameters);
        params = filenames;
        params(end+1) = {'locutoff'};
        params(end+1) = {ledge};
        params(end+1) = {'highcutoff'};
        params(end+1) = {hedge};
        study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'Filter', 'function', 'study_Filter_GUI', 'paramstring', params, 'fileID', file_id);
        study = study_SaveStudy(study);
        closereq();
    catch ME
        close(pbar);
        closereq();
        rethrow(ME)
    end


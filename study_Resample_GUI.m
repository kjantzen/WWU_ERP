function h = study_Resample_GUI(study, filenames)

p = plot_params;

scrsize = get(0, 'ScreenSize');
Wdth = 400; Hght = 130;
Bttn_HalfWidth = 12;
Bttn_HalfHeight = 18;
LBHeight = Hght * .95;

%setup the main figure window
handles.figure = uifigure;
h = handles.figure;

%
EEG = wwu_LoadEEGFile(filenames{1});

set(handles.figure,...
    'Color', p.backcolor, ...
    'Name', 'Resample Data',...
    'NumberTitle', 'off',...
    'Position', [(scrsize(3)-Wdth)/2,(scrsize(4)-Hght)/2,Wdth,Hght],...
    'Resize', 'off',...
    'menubar', 'none',...
    'WindowStyle', 'modal');

%*************************************************************************
handles.edit_currFs = uieditfield(handles.figure, ...
    'numeric',...
    'Value', EEG.srate,...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor, ...
    'Position', [180, 95, 100, 20],...
    'Editable','off');

handles.edit_newFs = uieditfield(handles.figure, ...
    'numeric',...
    'Limits',[64, EEG.srate],...
    'RoundFractionalValues','on',...
    'Value', EEG.srate/2,...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor, ...
    'Position', [180, 65, 100, 20]);

uilabel('Parent', handles.figure, ...
    'Text', sprintf('Current Sample Rate (Hz)'),...
    'HorizontalAlignment', 'left', ...
    'BackGroundColor', p.backcolor, ...
    'Position', [20, 95, 150, 20]);

uilabel('Parent', handles.figure, ...
    'Text', sprintf('New Sample Rate (Hz)'),...
    'HorizontalAlignment', 'left', ...
    'BackGroundColor', p.backcolor, ...
    'Position', [20, 65, 150, 20]);

handles.check_overwrite = uicheckbox(...
    'Parent', handles.figure,...
    'Value', 0,...
    'Text', 'Overwrite input files',...
    'Position', [130, 40, 150, 20]);

handles.button_resample = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Resample',...
    'Position', [Wdth-p.buttonwidth-10, 5, p.buttonwidth, p.buttonheight],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.button_cancel = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Cancel',...
    'Position', [Wdth-(p.buttonwidth*2)-20, 5, p.buttonwidth, p.buttonheight],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor,...
    'ButtonPushedFcn', {@callback_close});

handles.button_resample.ButtonPushedFcn = {@callback_resample, handles, filenames, study};


%**************************************************************************
function callback_close(hObject, eventdata)
closereq();


%**********************************************
function callback_resample(hObject, eventdata, h, filenames, study)


    file_id = '_resamp';
    start = clock;

    newFs = h.edit_newFs.Value;
    owrite = h.check_overwrite.Value;
    
    try    
    %set a progress bar
    pbar = uiprogressdlg(h.figure,...
        'Title', 'resampling in progress',...
        'ShowPercentage', 'on');
   
    option = 0;
    nfile = length(filenames);
       
        for jj = 1:nfile
            [path, file, ext] = fileparts(filenames{jj});
            if owrite
                outfilename = file;
            else
                [file_id, option,writeflag] = wwu_verifySaveFile(path, file, file_id, ext, option);
                if option == 3 && ~writeflag
                    fprintf('skipping existing file...\n')
                    continue;
                else
                    outfilename = [file, file_id];
                end
            end
            
            EEGIn = wwu_LoadEEGFile(filenames{jj});
            fprintf('Resampling the data from %i to %i Hz\n', EEGIn.srate, newFs);
            
            EEGIn = pop_resample( EEGIn, newFs);
            newfile = fullfile(path, [outfilename, ext]);
            wwu_SaveEEGFile(EEGIn, newfile);
        
            pbar.Value  = jj/nfile;
    
        end
        
        clear EEGIn
        close(pbar)
    
        params = filenames;
        params(end+1) = {'new sample rate'};
        params(end+1) = {newFs};
        study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'Resample', 'function', 'study_Resanple_GUI', 'paramstring', params, 'fileID', file_id);
        study = study_SaveStudy(study);
    
    
        closereq();
    catch ME
        close(pbar);
        closereq();
        rethrow(ME)
    end


% WWU_UPDATEPROCESSLOG
% wwu_UpdateProcessLog(study, infoStruct) write information about a processing
% stage to a study specific excel file called PreProcessing.xlsx located in
% the study folder.  If the file is not found it is created automatically.
% This funciton is called automatically during specific processing stages 
% to support detailed analysis and reporting of particiapnt sepcific 
% processing outcomes including
%   -number of channels removed
%   -number of bad trials
%   -number of components removed
%   -trials per average
%
% Inputs
%   study - an hcnd_eeg study structure
%   inStruct - an as yet to be determined data structure
%
function wwu_UpdateProcessLog(study, d)

%do some better checking here later when I know what I need in the
%structure
arguments
    study 
    d.SheetName {mustBeText}
    d.ColumnNames (1,:) {mustBeUnderlyingType(d.ColumnNames, 'cell')}
    d.RowNames (:,1) {mustBeUnderlyingType(d.RowNames, 'cell')}
    d.Values 
    d.Parameters
end
    
outputFile = 'ProcessingLog.xlsx';
eegPath = study_GetEEGPath;
processFile = fullfile(eegPath, study.path, outputFile);

%determine if the excel file exists already
if isfile(processFile)
    allSheets = sheetnames(processFile);
    sheetNum = length(allSheets) + 1;
    d.SheetName = sprintf('(%i) %s', sheetNum, d.SheetName);
else 
    d.SheetName = sprintf('(%i) %s', 1, d.SheetName);
end

%add user and system information to the parameter list
d.Parameters.version = {'MATLAB Version', version};
if ismac
    d.Parameters.plafform = {'Platform', 'Mac'};
    [~,user] = system('id -F');
    d.Parameters.user = {'User', strip(user)};
elseif ispc
    d.Parameters.platform = {'Platorm', 'PC'};
    d.Parameters.user = {'User', getenv('USER')};
end

%write data to the new data sheet
%first write the paramters
fields = fieldnames(d.Parameters);
for ii = 1:length(fields)
    writecell(d.Parameters.(fields{ii}), processFile,'Sheet', d.SheetName,'WriteMode','append');
end

%then write a table with filelist as row names and the valuename as column
%header and values as the table values
if iscell(d.Values)
    t = cell2table(d.Values, 'RowNames', d.RowNames, 'VariableNames',d.ColumnNames);
else
    t = table(d.Values, 'RowNames', d.RowNames, 'VariableNames',d.ColumnNames);
end
writetable(t, processFile, 'Sheet', d.SheetName, 'WriteMode','append','WriteRowNames',true, 'WriteVariableNames', true);

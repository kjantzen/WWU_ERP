function path = eeg_BuildPath(varargin)

for ii = 1:nargin
    ppart(ii) = varargin(ii);
    ppart{ii} = regexprep(ppart{ii}, '\', filesep);
    ppart{ii} = regexprep(ppart{ii}, '/', filesep);
end
path = fullfile(ppart{:});

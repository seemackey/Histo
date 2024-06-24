% Define the groups and cases
M_long = [109, 110, 114, 124, 125];
F_long = [119, 120, 122, 123];
M_short = [117, 118, 121];
control = [111, 112, 113];
groupNames = {'M_long', 'F_long', 'M_short', 'control'};
groups = {M_long, F_long, M_short, control};

% Initialize variables to store extracted data
groupCol = {};
subjectCol = {};
earCol = {};
freqCol = {};
volumeCol = [];

% Extract data from groupedData into columns
for k = 1:length(groupNames)
    group = groupNames{k};
    groupCases = groups{k}; % Get the case IDs for the current group

    for caseID = groupCases
        caseIDStr = ['x' num2str(caseID)];
        
        % Check both L and R versions of the case
        for suffix = ["L", "R"]
            if isfield(groupedData.(group), caseIDStr) && isfield(groupedData.(group).(caseIDStr), suffix)
                caseData = groupedData.(group).(caseIDStr).(suffix);
                freqNames = fieldnames(caseData);
                
                for j = 1:length(freqNames)
                    freq = freqNames{j};
                    volumes = caseData.(freq);
                    
                    % Repeat the group, subject, ear, and frequency for all volumes
                    numVol = length(volumes);
                    groupCol = [groupCol; repmat({group}, numVol, 1)];
                    subjectCol = [subjectCol; repmat({caseIDStr}, numVol, 1)];
                    earCol = [earCol; repmat({suffix}, numVol, 1)];
                    freqCol = [freqCol; repmat({freq}, numVol, 1)];
                    volumeCol = [volumeCol; volumes];
                end
            end
        end
    end
end

% Convert frequency from string format (e.g., 'x0_2') to numeric
freqNum = cellfun(@(x) str2double(strrep(x(2:end), '_', '.')), freqCol);

% Create a table for mixed effects model
dataTbl = table(groupCol, subjectCol, earCol, freqNum, volumeCol, ...
    'VariableNames', {'Group', 'Subject', 'Ear', 'Frequency', 'Volume'});
%%
% Convert categorical variables
%dataTbl.Group = categorical(dataTbl.Group);
dataTbl.Group = categorical(dataTbl.Group, {'control', 'M_long', 'M_short', 'F_long'}); % Set 'control' as reference
dataTbl.Subject = categorical(dataTbl.Subject);
dataTbl.Ear = categorical(cellfun(@char, earCol, 'UniformOutput', false)); % Ensure Ear is a char array

%%
%  formula for the mixed effects model
% Random intercepts for subject and ear nested within subject
formula = 'Volume ~ Frequency * Group + (1|Subject) + (1|Subject:Ear)';

% Fit the linear mixed-effects model
lme = fitlme(dataTbl, formula);

% Display the model summary
disp(lme);
%%
formula2 = 'Volume ~ Frequency^2 * Group + (1|Subject) + (1|Subject:Ear)';

% Fit the linear mixed-effects model
lme_quadratic = fitlme(dataTbl, formula2)




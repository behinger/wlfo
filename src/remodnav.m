function ev = remodnav(EEG)
% You need to install remodnav first!

% find x/y channel
ix = ismember({EEG.chanlocs.labels},{'EYE-X','EYE-Y'});

% write to temporary file
%csvwrite('tmp.csv',EEG.data(ix,:)')
%csvwrite is slooooooww

fid = fopen( 'tmp.csv', 'w' );
fprintf( fid, '%f\t%f\n', EEG.data(ix,:)' );
fclose( fid );

% run remodnav from python

%[status,cmdout]  =  system(['remodnav "fake" "tmp.csv" "remodnav_out.tsv" 1 ' num2str(EEG.srate) ' "--log-level" "warn"'])
[status,cmdout] = system(['python -c ''import remodnav;remodnav.main(["fake", "tmp.csv", "remodnav_out.tsv", "1.", "' num2str(EEG.srate) '", "--log-level","warn"])'''])
if status ~=0
    fprintf(cmdout)
    error('Read error above first. If it is something like "Couldnt find remodnav", try 1) activating the correct venv/conda environment within the command, e.g. before the "python", run "conda activate environment", or "source venv/Scripts/activate;python -c ..." 2) installing it using "system(''pip install remodnav'')" - if this doesnt work, then you have to move matlabs python to a virtualenv with remodnav installed')
    
end
% delete temporary file
delete('tmp.csv')

% read it in matlab
tRemo = readtable('remodnav_out.tsv','FileType','text');

% analyse only some events (i.e. remove PSOs)
ix = ismember(tRemo.label,{'FIXA','ISAC','SACC','PURS'});
ev = table2struct(tRemo(ix,:))';

% convert onsets to latency
for e = 1:length(ev)
    ev(e).latency = ev(e).onset*EEG.srate;
    ev(e).type = ev(e).label;
end
ev = rmfield(ev,'label');

end

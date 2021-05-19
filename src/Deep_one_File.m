EEG = pop_loadset('data/ITW_Wild_subj47_4_continous_Engbert.set')
remodnav(EEG)
%%
EEG_to_arff(EEG,2:4,'test3')
EEGf = pop_eegfiltnew(EEG,0.5);
%%
% system("python blstm_model_run.py --input path/to/extracted/feature/file.arff --output folder/where/to/put/the/result.arff --model path/to/model/folder/or/file --feat xy speed direction

%%
[dDeep, metadata, attributes, relation, comments] = LoadArff('lib/deep_em_classifier/test3_result.arff');

tDeep = array2table(dDeep(:,[1:3,end]),'VariableNames',attributes([1:3,end],1));
tmp = {'UNKNOWN','FIX','SACCADE','SP','NOISE','BLINK','NOISE_CLUSTER','PSO'};
tDeep.eye_movement_type = tmp(tDeep.eye_movement_type)';
%%
tRemo = readtable('src/tmp2.tsv','FileType','text');

g = gramm('x',tRemo.duration,'color',tRemo.label);g.stat_density();g.draw()



%%

% add only Fix
ix = ismember(tRemo.label,{'FIXA','ISAC','SACC','PURS'});

ev = table2struct(tRemo(ix,:))';
EEGf.event = ev;

for e = 1:length(EEGf.event)
    EEGf.event(e).latency = EEGf.event(e).onset*EEGf.srate;
    EEGf.event(e).type = EEGf.event(e).label;
end


EEGfe = pop_epoch( EEGf, {  'SACC'  }, [-0.1         0.1], 'newname', 'Merged datasets epochs', 'epochinfo', 'yes');
EEGfe = pop_rmbase(EEGfe,[-70 -50]);
figure,plot(EEGfe.times,squeeze(EEGfe.data(1,:,:)))
g = gramm('x',tRemo.peak_vel,'color',tRemo.label);g.stat_bin('geom','line','edges',0:10:1000);g.draw()

%%
figure
ix = ({EEG.event.type} == "fixation") | ({EEG.event.type} == "saccade");
g = gramm('x',[EEG.event(ix).duration]/EEG.srate,'color',{EEG.event(ix).type});g.stat_bin('geom','line','edges',0:0.01:1);g.draw()
figure
g = gramm('x',tRemo.duration,'color',tRemo.label);g.stat_bin('geom','line','edges',0:0.01:1);g.draw()
%%
[EEG.event(ix).latency]

using unfold
using Printf, AlgebraOfGraphics, CSV, StatsModels, WGLMakie, AbstractPlotting

include("dev/unfold/test/debug_readEEGlab.jl")

allData = []
allEvts = []

for sub = [08,09,16,17,18,19,20,21,22,23,24,25,27,28,29,30,31,32,33,34,35,36,38,39,40,41,44,45,47,48,51,52,53]
    print("subject: $sub")
    dir = @sprintf("/home/ehinger/store/data/WLFO/derivates/preproc_agert/sub-%02i/eeg/",sub)
    eegdata,srate,evts_df,chanlocs_df = import_eeglab(dir*@sprintf("sub-%02i_task-WLFO_eeg.set",sub ))

    evts_df = DataFrame(CSV.File(dir*@sprintf("sub-%02i_task-WLFO_events.tsv",sub ),delim="\t"))
    evts_df[:,:subject] .= sub
    
    append!(allEvts,[evts_df])
    append!(allData,[eegdata[[31,64],:]])
end

allEvts[1][:,:latency] = round.(allEvts[1].onset*512)
for k = 2:length(allEvts)
    allEvts[k][:,:latency] = round.(allEvts[k].onset*512 .+ sum(size.(allData[1:(k-1)],2)))
end
data_wlfo = cat(dims=2,allData...)
evts_wlfo = vcat(allEvts...)
categorical!(evts_wlfo,:subject)
categorical!(evts_wlfo,:picID)
# cut the data into epochs
f_fix  = @formula 0 ~ 1 + (1|subject)+(1|picID)# + +spl(sac_amplitude,4)

#evts = evts_wlfo[(evts_wlfo.type.=="fixation").&(evts_wlfo.subject.==8),:]
evts = evts_wlfo[(evts_wlfo.type.=="stimulus"),:]

data_epochs,times = unfold.epoch(data=data_wlfo,tbl=evts,τ=(-0.3,0.8),sfreq=512,eventtime=:latency);
# missing or partially missing epochs are currenlty _only_ supported for non-mixed models!
evts_wlfo2,data_epochs = unfold.dropMissingEpochs(evts,data_epochs)
@time m,results = unfold.fit(UnfoldLinearMixedModel,f_fix,evts_wlfo2,data_epochs,times) 


using AlgebraOfGraphics, AbstractPlotting,WGLMakie
m = mapping(:colname_basis,:estimate,group=:channel,color=:term,layout_x=:term,layout_y=:group)
AlgebraOfGraphics.data(results[results.channel.==2,:]) * visual(Lines) * m  |> draw

#----- OVERLAP MIXED MODEL WAAAA
srate = 512/8.
b_stim = firbasis(τ=(-0.3,1.2),sfreq=srate,name="stimulus")
b_fix  = firbasis(τ=(-0.5,0.5),sfreq=srate,name="fixation")

evts_wlfo.subjectB = evts_wlfo.subject

f_stim = @formula 0 ~ 1 + (1|subject)
f_fix  = @formula 0 ~ 1 + (1|subjectB)
evts_wlfo.latency2 = round.(evts_wlfo.latency./8) 
X_stim = designmatrix(UnfoldLinearMixedModel,f_stim,evts_wlfo[evts_wlfo.type.=="stimulus",:],b_stim,eventfields=:latency2)
X_fix  = designmatrix(UnfoldLinearMixedModel,f_fix ,evts_wlfo[evts_wlfo.type.=="fixation",:],b_fix,eventfields=:latency2)

X_comb = X_stim + X_fix
@time fit = unfoldfit(UnfoldLinearMixedModel,X_comb,data_wlfo)

df = condense_long(fit)


m = mapping(:colname_basis,:estimate,color=:term,layout_x=:term,layout_y=:basisname)
AlgebraOfGraphics.data(df[df.channel.==2,:]) * visual(Lines) * m  |> draw

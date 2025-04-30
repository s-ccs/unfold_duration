#import "@preview/chemicoms-paper:0.1.0": template, elements;
#import "@preview/equate:0.2.0": equate

#set page(paper: "a4", margin: (left: 10mm, right: 10mm, top: 12mm, bottom: 15mm))

#show: template.with(
  title: [Brain responses vary in duration - modelling strategies and challenges],
  abstract: (
    [Typically, event related brain responses are calculated invariant to the underlying event-duration, even in cases where event-durations observably vary: with reaction times, fixation durations, word lengths or varying stimulus durations. Additionally, an often co-occurring consequence of differing event durations is a variable overlap of the responses towards single events. While the problem of overlap e.g. in BOLD-fMRI and EEG is successfully addressed using linear deconvolution, it is unclear whether deconvolution and duration covariate estimation can be jointly estimated, as both are dependent on the same inter-event-distance variability.
Here, we show that failing to explicitly account for event durations can lead to spurious results and thus are important to consider. Next, we propose and compare several methods based on multiple regression to explicitly account for stimulus durations. Using simulations, we find that non-linear spline regression of the duration effect outperforms other candidate approaches. Finally, we show that non-linear event duration modelling is compatible with linear overlap-correction in time, making it a flexible and appropriate tool to model overlapping brain signals. 
This allows us to reconcile the analysis of stimulus responses with e.g. condition-biased reaction times, condition-biased stimulus duration or fixation-related activity with condition-biased fixation durations.
While in this paper we focus on EEG analyses, these findings generalize to LFPs, fMRI BOLD-responses, pupil dilation responses and other overlapping signals.],

  ),
  venue: [],
  header: (
    article-color: rgb("#364f66"),
    article-type: "Preprint",
    article-meta: [Not Peer-Reviewed],
  ),
  authors: (
    (
      name: "René Skukies",
      corresponding: true,
      orcid: "0000-0002-4124-4584",
    ),
    (
      name: "Judith Schepers", 
      orcid: "0009-0000-9270-730X",
    ),
    (
      name: "Benedikt Ehinger", 
      orcid: "0000-0002-6276-3332",
    ),
  ),
  citation: [R. Skukies, J.Schepers and B. Ehinger, 2024]
)

#elements.float(align: bottom, [\*Corresponding author]) 
#set figure(gap: 0.5em) /* Gap between figure and caption */
#show figure: set block(inset: (top: 0.5em, bottom: 1.5em)) /* Gap between top/ bottom of figure and body text */
#show: equate.with(breakable: true, sub-numbering: true) /* Needed for multi line equations */
#set math.equation(numbering: "(1.1)")


= Introduction

== Event Related Potentials

Neural activity can only rarely be interpreted without removing undesired noise through averaging. Such averaging is most commonly performed time-point by time-point over multiple trial-repetitions relative to an event marker. Under the assumption of uncorrelated noise, averaging will, in the limit, remove all interferences which are inconsistent across trials, recovering the “true” underlying event-related signal. 

In human EEG, the result oft such averaging is known as the event-related potential (ERP) and has been studied for more than 80 years (Davis 1936). While in this article we primarily focus on such ERPs, we additionally show that our findings generalize to other event-related time series, such as fMRI, LFP, or pupillometry (@Fig1).

#figure(
  image("assets/2024-08-07_figu1.svg", width: 100%),
  caption: [Exemplary duration effects in different modalities. Simulations following published effects (Pupil: /* @snowden, BOLD: @glover */, fERP: this paper). A) normalized pupil response to varying stimulus durations. B) BOLD response to different block-durations of finger tapping. C) fERP responses to fixations of varying durations.],
)<Fig1>

A helpful example to visualize this process can be found in its application to a classical P300 experiment, commonly known as an oddball experiment. Here, subjects respond whether they see a rare “target” stimulus, or a frequent “standard” stimulus (@Problem .A). Typically, the signal of interest is the time-locked activity to the stimulus and, in some analyses, to the button press as well @jung.etal_1999. After averaging several trials, a reliable difference between target and distractor stimuli appears at around 350ms after the stimulus, the P300 @kappenman.etal_2021 @luck_2014. While single-trial analyses exist (most visceral with brain computer interfaces), the averaging step is really what makes ERP research possible.

== Event Durations as Confounding Factor

This classical averaging step, however, cannot account for trial-wise (confounding) influences. For instance, in averaging we typically assume that a “stationary” ERP exists on every single trial, but is contaminated with noise. If we think other effects can vary the overall shape of the ERP, then we can no longer use simple averaging as our analysis method.  Examples of this problem and how to address them have been discussed and spearheaded by Pernet & Rouseelete in their LIMO approach @pernet.etal_2011, with the rERP approach @smith.kutas_2015 and also in our own work for low-level stimulus confounds @ehinger.dimigen_2019 and for eye-movement attributes @dimigen.ehinger_2021.

Varying event durations could reflect one such trial-wise influence, expressed through external stimulation, e.g. how long the stimulus is presented in the experiment, as well as internal processes, e.g. how long a stimulus is processed by the brain. Especially the latter is a strong candidate for potential confounds, as stimulus processing times typically differ between conditions @gilbert.sigman_2007 @lange.roder_2006 and populations @der.deary_2006 (see @Problem .C for different reaction times between conditions). Processing times also naturally differ for fixation durations, e.g. in unrestricted viewing @nuthmann_2017 or for certain stimuli, e.g. faces which typically are fixated longer than other objects @gert.etal_2022.

Indeed, previous studies by #cite(<wang.etal_2018>, form: "prose"), #cite(<hassall.etal_2022>, form: "prose"), #cite(<yarkoni.etal_2009>, form: "prose"), #cite(<groen.etal_2022>, form: "prose") & #cite(<brands.etal_2024>, form: "prose"), #cite(<mumford.etal_2023a>, form: "prose") have shown the importance to regard duration as a potential confounder in single neuron activity, in EEG, iEEG and also fMRI. 
#cite(<wang.etal_2018>, form: "prose") recorded single neuron activity from medial frontal cortex in non-human primates, which performed a task to produce intervals of different lengths. Through this, they showed that neural activity temporally scaled with interval length. Building on this research, #cite(<hassall.etal_2022>, form: "prose") extended the idea of temporally scaled signals to human cognition. By using a general linear model containing fixed- and variable-duration regressors, they successfully unmixed fixed- and scaled-times components in human EEG data. Furthermore, #cite(<sun.etal_2024>, form: "prose") recently expressed concerns of reaction time, a prominent example of event duration, as an important confounding variable in response locked ERPs. Adding to this, #cite(<yarkoni.etal_2009>, form: "prose") and #cite(<mumford.etal_2023a>, form: "prose") emphasized the importance of considering reaction time in fMRI time series modelling.

In summary, these studies highlight the increasing importance of considering event duration as a crucial factor in neural and cognitive research. And indeed, researchers have started to explicitly include event duration as a predictor in their models @nikolaev.etal_2023. By acknowledging and addressing the role of event duration, future research can achieve a more comprehensive understanding of cognitive processes and mitigate potential confounds, thereby enhancing the accuracy and reliability of findings in this field.

== Overlapping Events

Instead of averaging, a promising solution to solve this issue is the regression ERP (rERP) framework @smith.kutas_2015a where mass univariate multiple regression is applied to all time-points of the epoch around the event @fromer.etal_2018 @hauk.etal_2006 @pernet.etal_2011 @smith.kutas_2015. This flexible framework allows us to incorporate covariates varying over trials, like reaction time, fixation duration or stimulus duration, and statistically adjust for covariate imbalances between conditions (e.g. a faster reaction time towards the standards than the targets in the P300 experiment). The rERP approach further allows employing additive models that break the shackles of linear covariate modelling and allow for arbitrary smooth dependencies, which seem appropriate for complex neural activity as expected by duration effects.  In the last few years, the workflow using these approaches greatly improved, as new, specialized and user-friendly toolboxes e.g. LIMO, or Unfold @dimigen.ehinger_2021@ehinger.dimigen_2019@pernet.etal_2011 were developed. 

This leaves us with an angle to tackle the duration problem, but what about the overlap issue? Prior research has shown that overlap, as described above, can be addressed within the same regression framework, by using linear deconvolution modelling @ehinger.dimigen_2019 @smith.kutas_2015a Cornelissen 2018. This approach has been successfully applied to several experiments, with application to free viewing tasks (e.g. @coco.etal_2020 @gert.etal_2022 @nikolaev.etal_2023 @welke.vessel_2022), language modelling @momenian.etal_2024, auditory modelling @skerritt-davis.elhilali_2018 and many other fields.

This leaves us with a conundrum, however: the linear deconvolution works due to the varying-event timing, but the varying-event timing relates also to the duration effect. Therefore, it is not at all clear whether these two factors, overlap and varying event-duration, can, should, or even need to be modelled concurrently.

Here, we propose to incorporate linear deconvolution as well as event duration as covariates into one coherent model to estimate the time course of an ERP. If possible, we could disentangle the influence of both factors and get a better estimate of the true underlying ERP. We further propose to use non-linear spline regression to model the duration effect in a smoother and more flexible way than would be possible with linear regression.

To show the validity of our approach, we make use of systematic simulations and compare spline-regression with multiple alternative ways of modelling event duration. We further explore  potential interactions with overlapping signals. 

#figure(
  image("assets/20240807Fig2_ProblemRTeffect.svg", width: 100%),
  caption: [Potential influence of reaction in an Oddball task. (A) experimental sequence of the classical active oddball task; Reaction time from the participant controls the duration of a trial. (B) Observed EEG during the task (bottom) and underlying single event responses. (C) Distribution of response times between conditions of a single subject in an active oddball task from the ERP core dataset (Kappenman et al. 2021). (D) Isolated response to stimulus and response, including the effect of reaction time on the stimulus response. (E) Results from a classical average ERP analysis. Many artefactual differences are visible. (F) Average ERP after overlap correction. (G) ERP after overlap correction and covariate control through general additive modelling, showing that no condition effect was simulated. For a similar figure showcasing fixation related potentials and the effect of fixation duration, see figure 2 in #cite(<dimigen.ehinger_2021>, form: "prose") and for face-related activity #cite(<ehinger.dimigen_2019>, form: "prose").],
) <Problem>

= Methods

== Simulation Approach

We sought to explore whether it is possible to model both event duration and overlap, two co-dependent factors, in one combined model. However, a problem with real world EEG data is that we have no access to the true underlying ERP. Thus, we first turned towards simulations for which we can generate known “ground truths”, which vary with a continuous factor of duration, and which can be combined to one overlapping continuous signal by specifying the inter-event-onsets. Subsequently, we can apply our proposed analysis method and directly compare the results with the ground truth.


#figure(
  image("assets/20240618SimMethods.svg", width: 100%),
  caption: [Simulation methods; (A) three different “proto-ERPs” (i.e. ground truths) and the effect the duration factor can have on the respective shape; (B) A single continuous simulation with “scaled hanning” as ground truth with the underlying single overlapping ERPs. Notice the perfect correlation between event distance and duration; (D) the same continuous simulation with noise added.],
)<Methods>

As “proto-ERPs” (i.e. ground truth) representing our duration-modulated event-signal, we used a hanning window, varying the shape in three different ways: Stretching the later half along the x-axis by the duration effect, i.e. in time (@Methods, (A) left panel; termed “half hanning”); stretching the whole shape along the x-axis by the duration effect (@Methods, (A) middle panel; termed “hanning”); and stretching the hanning window along both axes, i.e. in time and amplitude (@Methods, (A) right panel; termed “scaled hanning”). We selected this set of shapes, since they seem to reflect several physiological plausible mechanisms, as they come close to the variable responses that #cite(<wang.etal_2018>, form: "prose") found in their study. Other, more complex shapes, e.g. based on adding duration-independent positive and negative peaks (like in a P1-N1-P3 ERP) did not show any qualitative difference in results. 

The parameters of the simulations were: shape (half-hanning, hanning, scaled hanning), duration effect (yes/no), temporal overlap (yes/no). In case of temporal overlap, we sampled inter-event-distances either from a uniform (from=0, to=3.5)  or a halfnormal (mu=0, std=1, truncated at 0) distribution. We chose these distributions as the former mimics experimatentally set stimulus durations, while the latter mimics fixation durations from a free viewing task. For each combination, we generated 500 individual “proto-ERPs”. These ERPs were then added together based on the simulated onsets to get one continuous EEG signal and the accompanying event latencies (see @Methods B for the individual ERPs of one simulation with overlap and the corresponding continuous signal). 

Additionally, ERPs were grouped together into blocks, each block containing activity from 25 ERPs, with inter-block-intervals containing no ERP activity (@Methods B), similar to an fMRI block-design, but with the stark distinction that we analyse it as an event-based design due to the higher temporal resolution of EEG. We decided on simulating these blocks only after finding a discrepancy in results between initial simulations, which didn’t incorporate inter-block-intervals and our real co-registered eyetracking/EEG data. As such, the inter-block-intervals in our simulations mimic inter stimulus intervals between stimuli of a free-viewing task. For a more thorough discussion on this point, why it’s important and its effects on the results, please see section @block.

=== Noise

Subsequently, for each simulation, we added real EEG noise by randomly selecting a minimally pre-processed closed eyes resting-state recording from one of 64 channels of 11 participants of a previously recorded study (#cite(<skukies_2020>, form: "prose") ; for specifics on the preprocessing see Appendix). Additionally, since the recordings tended to be shorter than the simulation, recordings were artificially prolonged by repeating the chosen recording until it matched the length of the simulation. After adding the noise, the data were FIR filtered at a -6db cut-off frequency of 0.5Hz. All simulations were repeated without noise as well, however since the main results did not change, we do not further discuss them here (see appendix for results without noise). Based on experience and the fact that only minimally process the noise recordings, we judge the noise-level to be realistic, and rather on a more noisy level. Our simulations pertain to a single subject, but our free-viewing example results are based on a group of subjects, greatly increasing the SNR. 

=== Analysis

We analysed the generated continuous time-series using rERP linear deconvolution based on multiple regression. We varied three analysis parameters: overlap-correction (yes/no) and duration-modelling (four different approaches to model duration plus simply averaging over epochs, see below), effectively forming a 5x2 design of analyses. However, the classical averaging was only calculated in order to compare duration modelling to the current standard practice of not modelling duration at all, we show all results relative to the classical averaged ERP (Wilkinson Formula: $y ~ 1$), which truthfully left us with a 4x2 design.

For the first approach, we introduce a linear duration effect to model duration (Wilkinson Formula: $y ~ 1 + italic("dur")$, termed duration-as-linear). 

For the second approach , we binned the event durations into their 10 quantiles, and estimated a separate ERP for each of them, (Wilkinson Formula: $y ~ 1 + italic("bin"("dur"))$, termed duration-as-categorical). This was done as it is a straight forward solution, even though criticised by prominent statisticians as “dichotomania” @greenland_2017, especially in pharmaceutics and the medical field @giannoni.etal_2014@senn_2005. Applied to our case, this means that there are no “optimal” thresholds (i.e. our bin edges) where the data of a continuous variable “jumps” to a different level. But by forcing continuous duration into (somewhat) arbitrary bins, we introduce unrealistic assumptions into our analysis. Yet, this practice has still been presented as a favourable analysis over classical averaging, and leading to an increase in power @poli.etal_2010.

Fourth and fifth, we make use of the generalized additive modelling framework (GAM) and use a regression B-spline with two different levels of model flexibility (Wilkinson Formula: $y ~ 1 + italic("spline"("dur", "df"=5))$, and more flexibly: $y ~ 1 + italic("spline"("dur", "df"=10))$, termed duration-as-5spline & duration-as-10spline). 

While a few model estimations were evaluated qualitatively by plotting their time courses @Quali, the full set of simulations was evaluated by computing the mean squared error (MSE) between the respective model predictions and the ground truth at the 15 quantiles of the duration predictors. Subsequently, MSE values were normalised against the model with no duration effect, that is, the classical averaged ERP. This means that resulting normalised MSE values < 1 indicated that a model was performing better than classical averaging, while values > 1 indicated worse performance.
Additionally to the five modelling approaches, we tested the influence of actively modelling overlap using linear deconvolution using the FIR-deconvolution approach popularized through fMRI @ehinger.dimigen_2019 @smith.kutas_2015a, against the passive method to try to resolve overlap via the duration coefficients @nikolaev.etal_2023.

The above procedure, i.e. every possible parameter combination, was repeated 50 times, resulting in a total of ~15.000 simulations.

== Applied Example

To showcase duration effects in a real dataset, we applied our approach to a previously collected free viewing Eyetrack-EEG dataset by #cite(<gert.etal_2022>, form: "prose"). The data was already preprocessed as follows: First the eyetracking and EEG data were integrated and synchronized using the EYE-EEG toolbox (http://www2.hu-berlin.de/eyetracking-eeg) @dimigen.etal_2014. Next, the data was downsamples from 1024 Hz to 512 Hz and high-pass filtered at 1Hz (-6 db cutoff at .5 Hz). Muscle artefacts and noisy channels were manually inspected and marked or removed respectively. Subsequently, ICA was computed, and artefactual components were subtracted. Lastly, data was re-referenced to an average reference and removed channels were interpolated through spherical interpolation. For more specifics on the preprocessing, please see #cite(<gert.etal_2022>, form: "prose").

To showcase our approach, we then analysed the data using custom scripts and the Unfold.jl toolbox (Ehinger et al. 2022). The data was modelled with linear models following the Wilkinson notation: 

$ y"_fixation" ~ & 1 + \ 
  & italic("is_face") + \
  & italic("spl"("duration", 4)) + \
  & italic("spl"("sac_amplitude", 4)) + \ 
  & italic("spl"("fix_avgpos_x", 4)) + \ 
  & italic("spl"("fix_avgpos_y", 4)) $

$ y"_stimulus" ~ 1 $

Where _if_face_ represents whether in that fixation a face was fixated (yes/no), _duration_ the fixation duration; _sc_amplitude_ the saccade amplitude; _fix_avgpos_x_ & _fix_avgpos_x_  the average x & y position of the current fixation. Next to fixation duration, we incorporated the other covariates in the analysis as they are known to have an influence on the FRP @gert.etal_2022 @nikolaev.etal_2023, and we wanted to adjust for these factors when investigating fixation duration. Additionally, stimulus onsets were modelled using a $y ~ 1$ formula, as the onset of a stimulus can have huge overlapping effects on subsequent fixations @coco.etal_2020 @dimigen.ehinger_2021 @gert.etal_2022.

As in our simulations, the model was calculated once with, and once without overlap correction. Because we were only interested in the effect of duration, we then calculated marginalized effects of duration on the ERP, while holding all other covariates constant at their respective means.

Finally, we statistically tested for the duration effect with and without overlap, and for the difference of the duration effect between with and without modelling. As proposed in #cite(<pernet.etal_2011>, form: "prose"), we use a Hotelling T² test (implemented in HypothesisTests.jl), but on the spline coefficients to test them against the nullhypothesis of all coefficients being 0 across subjects. We subsequently calculate a Benjamini-Yekutieli, via MultipleTesting.jl @benjamini.yekutieli_2001 Gehring [2014] 2024), false discovery rate correction over all channels and time points to adress the multiple comparison problem. As FDR does not control the FWER rate, we found many false-positives in the baseline, and, after seeing the data, opted for a more stringent alpha level of 0.005. Given that the results influenced our decision of threshold, a classical Pearson-Neyman interpretation is no longer valid, and we rather interpret our result in a Fisherian view, everything below 0.05 is worth another look, and we only use the alpha level to more conveniently describe what is significant, and to display significant electrode and time points.

For visualization, we estimate marginal effects over a range of durations (-0.1 to 1s).
To visualize our results in a topoplot series @mikheev.etal_2024a, we break down the multi-parameter spline estimate to a single value per channel and time-point, we calculate the maximal marginal effect over the range durations calculated before. This has the unfortunate effect, that what is tested, is not the same as what is visualized, the reason being the lacking visualization tools for non-linear effects. We used the UnfoldMakie.jl and Makie.jl libraries (version XX) for visualization.

= Results

We simulated ERPs with varying event-durations and tried to recover the simulation kernel using four different modelling strategies: duration-as-linear, duration-as-categorical, duration-as-5splines, and duration-as-10splines. 

In @Quali we show a representative analysis of one such simulation, using the scaled hanning shape, realistic noise and overlap between subsequent events. Two results immediately spring to mind here, foreshadowing our later quantified conclusions:

1) The overall best recovery of the simulation-kernel is achieved in the lower row, first panel from the right, the duration-as-10 splines predictor.

2) Comparing the top and bottom row, without and with overlap correction, shows that only with overlap correction can we get close to recovering the original shape. Thus, purely modelling duration-effects, cannot replace overlap-correction.

#figure(
  image("assets/20240620QualiResultsScaledHanning.svg", width: 100%),
  caption: [Results from a single simulation for the four tested models (including duration as: linear, categorical, 5-spline, 10-spline variable) combined with (bottom row) and without (top row) overlap correction. Bottom row legend = ground truth. Simulation parameters: Shape = scaled hanning;],
) <Quali>

However, it is important to keep in mind that this is only a single simulation. To generalize and quantify these potential effects, we calculated the mean-squared-error (MSE) between each analysis methods’ predictions and the ground truth, at 15 different event durations. All MSE values results are finally normalized to the results of fitting only a single ERP to all events, that is, modelling no duration effect at all (@MainResults).

#figure(
  image("assets/20240619ResultsFigure.svg", width: 100%),
  caption: [Normalized mean squared error results for the four tested models (including duration as: linear, categorical, 5-spline, 10-spline variable) in different simulation settings. Black line (y-value one) indicated results from classical averaging; MSE of zero indicated perfect estimation of the ground truth. (A) Results when a duration effect,  but no overlap is simulated. The spline strategies outperform the other strategies. (B) Results when no duration effect and no overlap was simulated, but duration effects were still estimated. Little overfit is visible here. (C) Results when duration effects were simulated, and signals overlap, and overlap correction is used for modelling. No interaction between duration modelling and overlap correction was observed on the MSE performance. (D) Results when duration was simulated, and signals overlap, but results are not overlap corrected. This indicates that duration modelling cannot replace explicit overlap modelling.],
)<MainResults>

In the following we will present the results of four different simulation settings, modifying both, whether we simulate overlap and duration effects, but also whether we use overlap correction in the analysis. To keep things (relatively) simple, we will first present these results by looking at simulations from only one shape (scaled hanning) and one duration sample distribution (half normal). However, the general conclusions hold true regardless of shape and sampling distribution, as discussed later.

== The Best Suited Way to Model Duration-Effects

First, we simulated duration effects and analysed them using several duration-modelling approaches to investigate their performance compared to not modelling the duration at all (equivalent to a single averaged ERP). @MainResults .A shows the smallest relative MSE for the spline-basis with 5 or 10 splines. This indicates, foremost, that modelling duration effects is superior to not modelling it, but also shows that using splines to model duration effects is superior to using a linear or categorical duration predictors.

To check for potential overfit, we repeated the simulation without simulating any duration effect, where the normalizing (classical averaging) model should perform best. Indeed, this is visible in @MainResults .B, and, as expected with a more flexible model, we also see a small indication of overfit in the linear and non-linear model fits, but importantly with a negligible size.

Taken together, the drawback of slight overfit in cases with no duration effect is in no relation compared to the benefit of being able to capture the variability a duration effect can introduce.

== Can we Model Duration-Effects and Overlap Simultaneously? <results>

Next we will introduce overlap between events, mimicking the process of a response ERP following a stimulus ERP, or more appropriate to our simulation setup, subsequent overlapping fixation-ERPs in a co-registered EEG/ET experiment. Given that shorter event-durations always co-occur with more overlap, and the event–distance describes both event-durations and overlap, it is not a-priori clear whether both can be disentangled simultaneously.

In the case of simulating duration and overlap, and analysing with overlap correction (@MainResults .C), we again find the result that duration-as-splines performs best. Indeed, even in our high-noise regime, the more flexible spline conditions outperform the others, without showing higher variance. This is direct evidence that overlap correction and duration-effect modelling can be used concurrently, even though the amount of overlap and the duration effect is strongly correlated by design and in nature.

#cite(<nikolaev.etal_2016>, form: "prose") and #cite(<vanhumbeeck.etal_2018>, form: "prose") raised the idea that overlap effects can be taken into account, using only a non-linear spline for the duration predictor, but never explicitly tested this in simulations. As visible in @MainResults .D (and compare not overlap corrected with overlap corrected results in @Quali above), this is not sufficient, indeed, not-modelling the overlap via duration even outperforms modelling it in our simulation setting. This shows us that we indeed have to, and can, rely on other techniques like linear deconvolution, as proposed in this study.

== Influence of Shape and Overlap Distribution

There are two more parameters of our simulations that we have not yet presented: overall shape of the ERP, and distribution of durations. The overall main conclusions hold true regardless of the set parameters.

#figure(
  image("assets/20240619ShapeDistributionEffect.svg", width: 100%),
  caption: [Normalized mean squared error results for the four tested models (including duration as: linear, categorical, 5-spline, 10-spline variable) between shapes (A-C) and duration distributions (color pairs). Black line (y-value one) indicated results from classical averaging; MSE of zero indicated perfect estimation of the ground truth. Parameter settings for all panels: duration affects shape; overlap simulated; overlap corrected/ modelled.],
)<DistResults>

Regardless of shape of the simulated proto-ERP and overlap distribution, spline-modelling of duration consistently gives us the best results (@DistResults A-C). However, MSE values and variance increase for the hanning shape (relative to the scaled hanning), and even further for the half hanning shape. The latter increase might be due to a saturation effect, if there is less variance in the duration effect to be explained in the first place, then a model without duration effect might perform similarly to a model explicitly modelling it (@DistResults colour pairs). We do not observe a consistent pattern of the influence of the distribution of overlap, but we cannot exclude more extreme choices.

== The Necessity of Block Experimental Structures <block>

In our initial simulation of duration combined with overlap correction, we noticed strong structured noise patterns, even when no signal was simulated (@BlockResults .B), that completely disappeared when event timings from real datasets were used. We systematically tested different potential sources and found that the block structure of most experiments, that is, having a break after a set of events (@BlockResults .A lower) resolves this issue. Note that this is not specific to one modelling strategy, but rather the artefact (Fig XB) can appear even with a linear effect. We quantitatively tested this finding and show that artificially introducing a break after every 25 events completely removes this artefact (@BlockResults .B vs. @BlockResults .C, @BlockResults .D). 

#figure(
  image("assets/20240717BlockFigure.svg", width: 100%),
  caption: [Comparison of simulations with and without simulated block structure. Up left: Ground truth shape “half hanning” used in the depicted simulation; (A) Continuous simulated EEG and its underlying responses without noise, once without (up), and once with (down) added blocks ; (B) Estimates from one simulation without added blocks, once without any signal in the data (left, i.e. the data contained only noise) and once with added signals (right, i.e. the data contained noise + signal); (C) Estimates from the same simulation, but with added blocks every 25 events, once without any signal in the data (left, i.e. the data contained only noise) and once with added signals (right, i.e. the data contained noise + signal); (D) Comparison of MSE results for all tested models in conjunction with overlap correction between simulations with blocks added (full colours) and simulations without any blocks added (cross-hatched colours).],
)<BlockResults>

We assume that when including the inter-event-distance both as a predictor, but also explicitly in the FIR time-expanded designmatrix, leads to a specific type of collinearity. This collinearity “blows up” the model estimates, and due to the duration effect, results in smooth wave-like patterns (@BlockResults .B). When introducing (seemingly) overlap-free events at the beginning and end of a block, this collinearity between the duration and the structure of the designmatrix is broken, and a “unique” solution can be estimated.

== Real World Example EEG + ET

We move our eyes approximately 120-240 times each minute. Besides being an interesting behavior in itself, eye movements offer a unique and data-rich segmentation event for EEG. . Consequently, more and more researchers use EEG and eyetracking to better understand human cognition @dimigen.etal_2014 @dimigen.ehinger_2021 @nikolaev.etal_2016. Here, EEG and eye movements are co-registered, such that single fixation can be used as event markers in the EEG. These fixations can then be assigned to different conditions based on the fixated stimulus, and modelled accordingly to achieve a fixation related potential.

To illustrate the interplay of duration and overlap modelling, we make use of a public co-registered unrestricted viewing dataset by #cite(<gert.etal_2022>, form: "prose"). 

As indicated in @AppliedResuts, without overlap correction we find three clusters of fixation duration effects along the midline: over frontal, occipital and centro-parietal electrodes.

#figure(
  image("assets/figure2_unfoldduration.svg", width: 100%),
  caption: [Results from a free viewing experiment. A) regression fERP's with marginal effects of fixation duration from channels AFz [left], Cz [middle] and Oz [right], once without [up] and once with [bottom] overlap correction. B) Topoplots for results without overlap correction [up], with overlap correction [middle], and the difference between with and without overlap correction [bottom]; Displayed values are the maximal difference between two evaluated marginal effects (i.e. the maximal difference between any line in A), whereas significantly marked channels were evaluated using a Hotelling-t test of the non-linear spline coefficients, which can lead to discrepancies of highest activity and significance. The significance of the difference was tested with a mass-univariate t-test against an difference of 0, corrected for multiple comparisons using FDR.],
)<AppliedResuts>

However, when modelling overlap in addition to duration, we found duration effects to become smaller and even vanish. This indicates that, as proposed by #cite(<nikolaev.etal_2016>, form: "prose"), that a duration predictor tries to compensate for the overlap (but ultimately failing to do so, see simulation results @results). Yet, an effect over central electrodes at around 0.XXX sec still persists in the results after overlap correction (@AppliedResuts). This is direct evidence for the existence of event duration effects in for EEG - EyeTracking co-registered data.

= Discussion

Event durations often differ between conditions and participants. While in some cases this can be controlled, in many cases it cannot - as soon as the event duration is under control of the subject e.g. differing reaction times in old vs young, or with the recent experimental trends towards quasi-experimental designs many aspects of an experiment are no longer under the control of the experimenter (cite TICS/ TINS paper?). Here, we first show that such a discrepancy can lead to spurious effects in the underlying brain responses. We next demonstrate that when explicitly modelling such event-duration effects, these spurious effects can be successfully addressed. Finally, we systematically evaluated that non-linear modelling of event durations is compatible with linear overlap correction and that implementing such analyses can give a better understanding of the true brain processes. 

== Modelling Event Durations

One of the key takeaways from our study is the potential for spurious effects in results from neural data when variations in event durations are not considered. In EEG research, earlier studies proposed to model durations by binning reaction times and calculating the average ERP of each bin @poli.etal_2010 or as a smooth predictor @vanhumbeeck.etal_2018. Contrary to what the problem of “dichotomania” @senn_2005 might suggest, our simulations show that categorizing durations into bins performs better than even linear modelling of duration. However, binning is still not able to capture the whole picture of a continuously changing shape, potentially leading to misleading results.

More generally, trial-by-trial influences of event durations have been discussed before in research of single unit recording @wang.etal_2018, fMRI @mumford.etal_2023a@yarkoni.etal_2009 and in M/EEG data @hassall.etal_2022@kopcanova.etal_2024. 

We show the critical role that duration plays in the interpretation of ERP results, and further that it takes the flexibility of non-linear spline estimation via multiple regression to model event durations to achieve meaningful results. As such, to ensure accuracy and reliability of results, duration effects cannot be ignored, but rather must be addressed.

== Compatibility with Linear Overlap Correction

The presence of overlap in EEG data is a common phenomenon. And although this problem  has been thoroughly addressed before @ehinger.dimigen_2019@smith.kutas_2015, it was not clear if modelling of event durations and overlap correction can be combined. That is, through a dependence of varying-event timings needed for linear deconvolution, which in turn are directly related to the duration effect, we were left with a potential collinearity problem.

Our simulations indicate that non-linear event duration modelling and linear deconvolution of adjacent events (i.e. overlap correction) can be seamlessly integrated. We also showed that this comes at a minimal cost in terms of potential overfit, should there be no ground truth duration effect in the data. We therefore recommend using our proposed non-linear duration modelling in cases researchers suspect effects of duration.

== Additional Things

In addition to overlap and duration simulation results, we varied four further parameters: ERP shape, block-design, jittering inter-onset-distances, and regularization.

ERP shape: Overall, results do not change drastically based on different ERP shapes, i.e. it is still best to model duration by non-linear spline modelling in conjunction with overlap correction. However, while results from two of our used shapes (scaled hanning and hanning) showed very similar results, the half hanning shape showed signs of increased overfit for 10-splines, with larger MSE compared to the best performing 5-splines. Currently, the number of splines in overlap corrected regression fits have to be chosen by hand, instead of an automatic penalized splines method due to computational reasons. Similarly, the variability of MSE values within model categories increased, especially for the more flexible models. This is likely to the shorter time window of the duration effect itself, and thus these flexible models are more prone to overfit on the noise in the earlier non-changing part of the shape. We cannot exclude more extreme shapes to show more extreme behaviour.

Block-design: As described in @block, a continuous stream of overlapping events without breaks leads to increased overfit under certain simulation conditions. Introducing “inter-block-intervals”, where at least two adjacent events break the homogeneous overlap-duration relationship, alleviates this issue. We think that such pauses break the correlation between inter-event-onsets as modelled with the FIR time expansion, and the duration predictor. Further simulations showed that this effect is not specific to splines, but also occurs with linear duration modelling. Further, this effect is irrespective of shape and occurs in pure noise data as well (see @BlockResults). However, by adding only one or more (depending on SNR) of the aforementioned inter-block-intervals, we could resolve this noise amplification.-

In real data such inter-block-intervals can occur, for example in free viewing experiments where FRPs are of interest. Here, while fixation duration and overlap are indeed perfectly correlated within the e.g. 5s of looking at a stimulus, the last fixation before removing the stimulus does have a duration, but no further (modelled) fixation overlapping. In other experiments, blocks can (and usually are) in the experiment by design.

Jittering inter-onset-distances: In our free viewing data, we also noticed that the inter-event-onsets and durations are not as perfectly correlated as in our simulation due to variable saccade duration. We therefore introduced  a uniform jitter of +-30ms (expected saccade duration) to the inter-event-onsets in our simulations. This had only a minimal effect, if any at all, in a subset of tested simulations. We did not test this systematically, as it is outside the scope of this paper.

Regularization: Lastly, we also ran some preliminary tests on L2 regularization (cite Kristennsen). Regularization should reduce overfit on the data at the expense of introducing a bias, in the case of L2 norm, towards coefficients with smaller amplitude. Typically, the amount of regularization is chosen by cross-validation, however in our simulations we often observed that this resulted in regularization completely to zero. In Unfold, currently only a “naive” cross-validation within the cvGLMNET solver (cite) is available. This method is insufficient solely because that cross-validation breaks are automatically set by the blackbox-function, and thus can be within-blocks, potentially leading to data-leakage between test and validation set. We are not aware of a sufficient implementation alleviating this. Nevertheless, we identified a second, more severe limitation than data leakage: There is only a single regularization parameter for the whole model, thus with overlap correction, we regularize all time-points relative to an event-onset equally. This means, that baseline periods, where the true regularization coefficient should be very high, as there is no reliable time-locked activity wash over to periods of activity, greatly reducing their amplitude, often to zero. Setting the regularization parameter by hand, as expected, leads to a strong reduction of this noise artefact, but at the cost of bias. Only more nuanced applications of regularization can fully address this issue, and more work is needed.

== Limitations in Filling the Gap

One clear limitation of our simulations is, that we only look at model performance of what essentially constitutes results from a single subject. We do not address in this paper how the performance will improve if estimates over multiple subjects are aggregated. In the applied example we do average results over multiple subjects, but here we want to highlight some a potential caveat relating to spline modelling in general: Experimenters need to decide whether to normalize durations per subject, effectively modelling quantiles over subjects, or assuming that ERPs relate better to absolute durations. Because knot-placement and coverage of splines depend on the distribution of each one single subject, not all subjects have the same  smoothing factor. Interested readers are pointed to Wood (202?) for a discussion of these issues. 

A more general limitation is, that we cannot know how such duration effects are implemented in the brain. This could potentially lead to an issue of causality, as the duration covariate is used to explain points in time at which the system has not yet actually specified the event duration. This limitation is not specific to this study, but in general whenever e.g. reaction times, or even behavioral responses are used to predict neural data.

Lastly, the performance of our results compared to the approach by #cite(<hassall.etal_2022>, form: "prose") remains to be shown. They assume a single response is stretched in time, setting a strong prior on the possible relation. Such a relation would be fulfilled in our simulation for the stretched hanning window, but not in the other shapes.

== Limitations in Generalization

In this study, we focused on three rather simple shapes for simplicities’ sake. These three shapes cover a range of possible changes to the shape in that they stretch in time, both in time and amplitude, or only partly, which are simplification of real examples @hassall.etal_2022@wang.etal_2018. However, although earlier simulations with more complicated shapes that included multiple positive and negative peaks showed no substantial differences in results, we cannot be certain how our results generalize to all possible shapes.

Furthermore, our study is in several cases limited to relative comparisons between analysis methods, where the spline-modelling performed best. This is not to mean that it ultimately recovers the underlying shape perfectly. Indeed, inspecting @Quali, one can clearly see that the pattern is not an exact recovery, but confounded by noise - still, it is performing much better than ignoring the issue and only using a single ERP. Similarly, we use only a single measure (MSE) to evaluate and delineate the different analysis methods, other choices of measures are possible (e.g. correlation, absolute error, removal of baseline period). We do not expect qualitatively different results.

Next, we did not investigate if there are interactions of the condition and the duration effect. That is, throughout the paper we assume that the duration effect is the same in all conditions. If we allow for such an interaction, then it is unclear to us, if these per-condition-duration-effects could be used to explain the main effects of conditions as well. 

Additionally, our simulation study covers a large area of simulation parameters, but cannot cover all possible cases. Indeed, some interesting variations could be to introduce continuous and categorical condition differences, multiple different event types, use more flexible non-linear analysis methods (e.g. DeepRecurrentAutoencoder (cite Jean-Remy King)) or try to simulate empirically found duration effects more realistically.

Lastly, we had a coarse look at different noise levels (unreported), and two noise-types (white and real noise). Both factors did not influence our conclusions or the relative order of the methods.

== Generalization to other Modalities

While we focus in this paper on applying our approach to M/EEG data, it can be extended to other neuroimaging techniques. In fact, it is plausible that almost all brain time series analyses could benefit from considering event duration, as potential confounders.

The first technique that comes to mind is functional magnetic resonance imaging (fMRI). fMRI has the advantage that the underlying measure generator is relatively well understood (as the hemodynamic response function; HRF). As such, the problem of overlapping signals has long since been thoroughly addressed @penny.etal_2011 However, a change in the HRF due to a different event duration is rarely considered. Some studies have shown the importance of modelling reaction times in fMRI studies @mumford.etal_2023a@yarkoni.etal_2009, however they modelled reaction time as a linear predictor rather than non-linear as indicated by our study. Further, both studies only focus on reaction time, whereas we argue to generalize such modelling to other event durations, such as stimulus durations or fixation durations

Another technique where our approach should prove useful in the investigation of local field potentials (LFP). This should come as no surprise, as LFP are inherently very close in analysis to EEG. That is, LFPs consists of fast-paced electrical fields (which might overlap in time) and are likely subject to change depending on the length of an event. In fact, at least one study in non-human primate already highlighted the relationship between task timing and LFPs @kilavik.etal_2010. However, their task involved the primates to execute one of two durations, over which was then aggregated, instead of considering duration as a continuous predictor. Additionally, overlap was not considered.

Lastly, pupil dilation measurements could benefit from our analysis approach as well. Typically, pupil dilation is taken as an indirect measurement of arousal states, cognitive load, and has been linked to changes in the noradrenergic system (Larsen and Waters 2018). Whereas pupil dilation has often been related to reaction time @hershman.henik_2019 @isabella.etal_2019 @strauch.etal_2020, none have modelled reaction time explicitly. At least one theory-driven model has been proposed which offers explanations for a wider range of parameters, including trial duration @burlingham.etal_2022. However, again overlapping signals are dismissed in this model, as such our more general approach is to be preferred.

= Summary

In the present study, we show through extensive simulations that event durations can be modelled in conjunction with overlap correction. Through combining linear overlap correction with non-linear event duration modelling, researchers gain a more powerful toolset to better understand human cognition. Overlap correction disentangles the true underlying signals of the ERPs, while event duration modelling can lead to a more nuanced understanding of the neural responses. 

By applying this analysis to real data, we underscore the importance of modelling event durations both, in cases where they are of interest itself, as well as in situations where durations may have an interfering influence on your results. 

As such, we advise researcher who study human time series data to take special care to consider if and how overlap and event durations affect their data.

#set heading(numbering: none)

= Conflicts of Interest
The authors have no conflicts of interest to declare. All co-authors have seen and agree with the contents of the manuscript and there is no financial interest to report.

= Data and Code Availability

All code is publicly available at https://github.com/s-ccs/unfold_duration. The FRP data can be obtained from Gert et al. (2022). 

= Funding
Funded by Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) under Germany's Excellence Strategy - EXC 2075 – 390740016. We acknowledge the support by the Stuttgart Center for Simulation Science (SimTech).

#set par(justify: true, first-line-indent: 0pt);

#bibliography(title:"Bibliography", style:"american-psychological-association", "2024UnfoldDuration.bib")
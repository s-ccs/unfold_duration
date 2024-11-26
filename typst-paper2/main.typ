//#import "@preview/chemicoms-paper:0.1.0": template, elements;
#import "@preview/arkheion:0.1.0": arkheion, arkheion-appendices
#import "@preview/equate:0.2.1": equate
#import "@preview/wrap-it:0.1.0": wrap-content

#set page(paper: "a4", margin: (left: 10mm, right: 10mm, top: 12mm, bottom: 15mm))
#set par.line(numbering: n => text(size: 6pt)[#n])
// #set par.line(numbering: "1")
//-> will work in next release ("soon")
#show: arkheion.with(
  title: "Brain responses vary in duration - modeling strategies and challenges",
  authors: (
    (name: "René Skukies", 
    email: "Rene.Skukies@vis.uni-stuttgart.de", 
    affiliation: "University of Stuttgart - SimTech", 
    orcid: "0000-0002-4124-4584"),
    
    (name: "Judith Schepers", 
    email: "Judith.Schepers@vis.uni-stuttgart.de", 
    affiliation: "University of Stuttgart", 
    orcid: "0009-0000-9270-730X"),
    
    (name: "Benedikt Ehinger", 
    email: "Benedikt.Ehinger@vis.uni-stuttgart.de", 
    affiliation: "University of Stuttgart - SimTech", 
    orcid: "0000-0002-6276-3332"),
  ),
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  abstract: [
    Typically, event-related brain responses are calculated invariant to the underlying event duration, even in cases where event durations observably vary: with reaction times, fixation durations, word lengths, or varying stimulus durations. Additionally, an often co-occurring consequence of differing event durations is a variable overlap of the responses to subsequent events. While the problem of overlap e.g. in fMRI and EEG is successfully addressed using linear deconvolution, it is unclear whether deconvolution and duration covariate modeling can be jointly used, as both are dependent on the same inter-event-distance variability.
Here, we first show that failing to explicitly account for event durations can lead to spurious results and thus are important to consider. Next, we propose and compare several methods based on multiple regression to explicitly account for stimulus durations. Using simulations, we find that non-linear spline regression of the duration effect outperforms other candidate approaches. Finally, we show that non-linear event duration modeling is compatible with linear overlap correction in time, making it a flexible and appropriate tool to model overlapping brain signals. 
This allows us to reconcile the analysis of stimulus responses with e.g. condition-biased reaction times, condition-biased stimulus duration, or fixation-related activity with condition-biased fixation durations.
While in this paper we focus on EEG analyses, these findings generalize to LFPs, fMRI BOLD-responses, pupil dilation responses, and other overlapping signals.
  ],
  keywords: ("event duration", "EEG", "regression ERP", "deconvolution", "rERP"),
  date: "10th October, 2024",
)

/*#show: template.with(
  title: [Brain responses vary in duration - modeling strategies and challenges],
  abstract: (
    [Typically, event related brain responses are calculated invariant to the underlying event duration, even in cases where event durations observably vary: with reaction times, fixation durations, word lengths or varying stimulus durations. Additionally, an often co-occurring consequence of differing event durations is a variable overlap of the responses towards single events. While the problem of overlap e.g. in BOLD-fMRI and EEG is successfully addressed using linear deconvolution, it is unclear whether deconvolution and duration covariate estimation can be jointly estimated, as both are dependent on the same inter-event-distance variability.
Here, we show that failing to explicitly account for event durations can lead to spurious results and thus are important to consider. Next, we propose and compare several methods based on multiple regression to explicitly account for stimulus durations. Using simulations, we find that non-linear spline regression of the duration effect outperforms other candidate approaches. Finally, we show that non-linear event duration modeling is compatible with linear overlap correction in time, making it a flexible and appropriate tool to model overlapping brain signals. 
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
*/

// to cite without parenthesis
/*
#let no-paren-cite(label) = {
  show regex("\(|\)"): none
  cite(label, form: "normal") 
}
*/ 

// set spellcheck language
#set text(lang: "en", region: "US")

// figure caption alighment
#show figure.caption: set align(left)

//#elements.float(align: bottom, [\*Corresponding author]) 
#set figure(gap: 0.5em) /* Gap between figure and caption */
#show figure: set block(inset: (top: 0.5em, bottom: 1.5em)) /* Gap between top/ bottom of figure and body text */

//#show: equate.with(breakable: false, sub-numbering: true) /* Needed for multi line equations */
#set math.equation(numbering: "(1.1)")

#set heading(numbering: "1." )

#pagebreak()
= Introduction

== Event-Related Potentials

Neural activity can only rarely be interpreted without removing undesired noise through averaging. Such averaging is most commonly performed time-point by time-point over multiple trial repetitions relative to an event marker. Under the assumption of uncorrelated noise, averaging will, in the limit, remove all interferences which are inconsistent across trials, recovering the “true” underlying event-related signal. 

In human EEG, the result of such averaging is known as the event-related potential (ERP) and has been studied for more than 80 years @davis_1936. While in this article we primarily focus on such ERPs, we additionally show that our findings generalize to other event-related time series, such as fMRI, LFP, or pupillometry (@Fig1).

#figure(
    image("assets/2024-08-07_figu1.svg"),
    caption: [Exemplary duration effects in different modalities. Simulations following published effects (Pupil: #cite(<snowden.etal_2016>, form: "prose"), BOLD: #cite(<glover_1999>, form: "prose"), FRP: this paper). A) normalized pupil response to varying stimulus durations. B) BOLD response to different block durations of finger tapping. C) FRP responses to fixations of varying durations.])<Fig1>

A helpful example to visualize the process of calculating an ERP can be found in its application to a classical P300 experiment, commonly known as an active oddball experiment. Here, subjects respond whether they see a rare “target” stimulus, or a frequent “standard” stimulus (@Problem\.A). Typically, the signal of interest is the time-locked activity to the stimulus and, in some analyses, to the button press as well @jung.etal_1999. After averaging several trials, a reliable difference between target and distractor stimuli appears at around 350ms after the stimulus onset, the P300 @kappenman.etal_2021 @luck_2014. While single-trial analyses exist (most visceral with brain-computer interfaces), the averaging step is what made ERP research possible.

== Event Durations as Confounding Factor

This classical averaging step, however, cannot account for trial-wise (confounding) influences. For instance, in averaging we typically assume that a “stationary” ERP exists on every single trial, but is contaminated with noise. If we suspect other effects can affect the overall shape of the ERP, then we can no longer use simple averaging as our analysis method.  Examples of this problem and how to address it have been discussed and spearheaded by Pernet & Rousselet in their LIMO approach @pernet.etal_2011, with the rERP approach @smith.kutas_2015 and also in our own work for low-level stimulus confounds @ehinger.dimigen_2019 and for eye-movement attributes @dimigen.ehinger_2021.

Varying event durations likely reflect one such trial-wise influence, manifested through external stimulation (e.g. how long a stimulus is presented in the experiment), as well as internal processes (e.g. how long a stimulus is processed by the brain). Especially the latter is a strong candidate for potential confounds, as stimulus processing times typically differ between conditions @gilbert.sigman_2007 @lange.roder_2006 and populations @der.deary_2006 (see @Problem\.C for different reaction times between conditions in an oddball experiment). Processing times also naturally differ for fixation durations, e.g. in unrestricted viewing @nuthmann_2017, or for certain stimuli, e.g. faces, which are typically fixated longer than other objects @gert.etal_2022.

Indeed, previous studies by #cite(<wang.etal_2018>, form: "prose"), #cite(<hassall.etal_2022>, form: "prose"), #cite(<yarkoni.etal_2009>, form: "prose"), #cite(<groen.etal_2022>, form: "prose"), #cite(<brands.etal_2024>, form: "prose") & #cite(<mumford.etal_2023a>, form: "prose") have shown the importance to regard duration as a potential confounder in single-neuron activity, in EEG, iEEG and also fMRI. 
#cite(<wang.etal_2018>, form: "prose") recorded single-neuron activity from the medial frontal cortex in non-human primates, which performed a task to produce intervals of motor activity (i.e. a hand movement towards a stimulus) of different lengths. Through this, they showed that neural activity temporally scaled with interval length. Building on this research, #cite(<hassall.etal_2022>, form: "prose") extended the idea of temporally scaled signals to human cognition. By using a general linear model containing fixed- and variable-duration regressors, they successfully unmixed fixed- and scaled-time components in human EEG data. Furthermore, #cite(<sun.etal_2024>, form: "prose") recently expressed concerns about reaction time, a prominent example of event duration, as an important confounding variable in response-locked ERPs. Adding to this, #cite(<yarkoni.etal_2009>, form: "prose") and #cite(<mumford.etal_2023a>, form: "prose") emphasized the importance of considering reaction time in fMRI time series modeling.

In summary, these studies highlight the increasing importance of considering event duration as a crucial factor in neural and cognitive research. And indeed, researchers have started to explicitly include event duration as a predictor in their models @nikolaev.etal_2023. By acknowledging and addressing the role of event duration, future research can achieve a more comprehensive understanding of cognitive processes and mitigate potential confounds, thereby enhancing the accuracy and reliability of findings in this field.

As mentioned above, one promising solution to address trial-wise influences through event duration is the regression ERP (rERP) framework @smith.kutas_2015a. Here, a mass univariate multiple regression is applied to all time points of an epoch around the event of interest @fromer.etal_2018 @hauk.etal_2006 @pernet.etal_2011 @smith.kutas_2015. This flexible framework allows us to incorporate covariates varying over trials, like reaction time, fixation duration, or stimulus duration, and subsequently statistically adjust for covariate imbalances between conditions (e.g., a faster reaction time towards the standards than the targets in the P300 experiment). The rERP approach further allows employing additive models that break the shackles of linear covariate modeling and allow for arbitrary smooth dependencies, which seem appropriate for complex neural activity as expected by duration effects. In the last few years, the workflow using these approaches greatly improved, as new, specialized, and user-friendly toolboxes e.g. LIMO @pernet.etal_2011, or Unfold @dimigen.ehinger_2021 @ehinger.dimigen_2019 were developed. 

== Overlapping Events

Having a method to tackle the duration problem still leaves us with the issue of temporal overlap between adjacent events, however. For instance, the stimulus ERP in an active oddball task, which is typically longer than 600ms, will necessarily overlap in time with the response ERP, which on average occurs after 430ms for distractor stimuli (see @Problem\.A-C). Prior research has shown such overlap, can be addressed within the same regression framework that is used to solve the covariate problem, by using linear deconvolution modeling @ehinger.dimigen_2019 @smith.kutas_2015a. This approach has been successfully applied to several experiments, with application to free viewing tasks (e.g. #cite(<coco.etal_2020>, form: "author"), #cite(<coco.etal_2020>, form: "year") @gert.etal_2022 @nikolaev.etal_2023 @welke.vessel_2022), language modeling @momenian.etal_2024, auditory modeling @skerritt-davis.elhilali_2018 and many other fields.

Yet, this leaves us with a conundrum: the linear deconvolution works due to the varying-event timing, but the varying-event timing also relates to the duration effect. Therefore, it is not at all clear whether these two factors, overlap and varying event duration, can, should, or even need to be modeled concurrently.

Here, we propose to incorporate event duration as a covariate as well as linear deconvolution into one coherent model to estimate the time course of an ERP. If possible, we could disentangle the influence of both factors and get a better estimate of the true underlying ERP. We further propose to use non-linear spline regression to model the duration effect in a smoother and more flexible way than would be possible with linear regression.

To show the validity of our approach, we make use of systematic simulations and compare spline regression with multiple alternative ways of modeling event duration. We further explore  potential interactions with overlapping signals. Lastly, we demonstrate the implications of our approach by applying it to a real free-viewing dataset.


#figure(
  image("assets/20241119Figure2.svg", width: 100%),
  caption: [Potential influence of reaction time in an oddball task. (A) Experimental sequence of the classical active oddball task; Reaction time of the participant controls the duration of a trial. (B) Observed EEG during the task (top) and underlying single-event responses. (C) Distribution of response times between conditions of a single subject in an active oddball task from the ERP core dataset @kappenman.etal_2021. (D) Isolated response to stimulus and response, including the effect of reaction time on the stimulus response. (E) Results from a classical average ERP analysis. Many artefactual differences are visible. (F) Average ERP after overlap correction. (G) ERP after overlap correction and covariate control through general additive modeling, showing that a condition effect is only attributed to a difference in reaction time distribution. For a similar figure showcasing fixation-related potentials and the effect of fixation duration, see Figure 2 in #cite(<dimigen.ehinger_2021>, form: "prose") and for face-related activity see #cite(<ehinger.dimigen_2019>, form: "prose").],
) <Problem>

= Simulations

== Approach

We sought to explore whether it is possible to model both event duration and overlap, two co-dependent factors, in one combined model. However, a problem with real-world EEG data is that we have no access to the true underlying ERP. Thus, we first turned towards simulations for which we can generate known “ground truths”, which vary with a continuous factor of duration, and which can be combined into one overlapping continuous signal by specifying the inter-event-onsets. Subsequently, we can apply our proposed analysis method and directly compare the results with the ground truth.


#figure(
  image("assets/20241119SimMethods.svg", width: 100%),
  caption: [Simulation methods; (A) three different “proto-ERPs” (i.e. ground truths) and the effect the duration factor can have on the respective shape; (B) A single continuous simulation with “scaled hanning” as ground truth with the underlying single overlapping ERPs. Notice the perfect correlation between event distance and duration, i.e. the longer the distance between two events, the more scaled is the hanning shape; (D) the same continuous simulation with noise added.],
)<Methods>

As “proto-ERPs” (i.e. ground truth) representing our duration-modulated event signal, we used a hanning window, varying the shape in three different ways:
stretching the hanning window along both axes, i.e. in time and amplitude (@Methods\.A) left panel; termed “scaled hanning”); stretching the whole shape along the x-axis by the duration effect (@Methods\.A) middle panel; termed “hanning”); and stretching the later half along the x-axis by the duration effect, i.e. in time (@Methods\.A right panel; termed “half hanning”). We selected this set of shapes since they seem to reflect several physiological plausible mechanisms, as they come qualitatively close to the variable responses that #cite(<wang.etal_2018>, form: "prose") found in their study. Other, more complex shapes, e.g. based on adding duration-independent positive and negative peaks (like in a P1-N1-P3 ERP) did not show any qualitative difference in results. 

Each simulation varied depending on multiple parameters: shape (half-hanning, hanning, scaled hanning), duration effect (yes/no), and  temporal overlap (yes/no). In the case of temporal overlap, we sampled inter-event distances either from a uniform (from=0, to=3.5)  or a half-normal (mu=0, std=1, truncated at 0) distribution. We chose these distributions as the former mimics experimentally set stimulus durations, while the latter mimics fixation durations from a free viewing task. For each combination, we generated 500 individual “proto-ERPs”. These ERPs were then added together based on the simulated onsets to get one continuous EEG signal and the accompanying event latencies (see @Methods\.B for the individual ERPs of one simulation with overlap and the corresponding continuous signal). 

Additionally, ERPs were grouped together into blocks, each block containing activity from 25 ERPs, with inter-block-intervals containing no ERP activity (@Methods\.B), similar to an fMRI block design, but with the stark distinction that we analyze it as an event-based design due to the higher temporal resolution of EEG. We decided on simulating these blocks only after finding a discrepancy in results between initial simulations, which didn’t incorporate inter-block intervals and our real co-registered eye-tracking/EEG data. As such, the inter-block-intervals in our simulations mimic inter-stimulus intervals between stimuli of a free-viewing task. For a more thorough discussion on this point, why this is important and its effects on the results, please see section @block.

=== Noise

Subsequently, for each simulation, we added real EEG noise by randomly selecting a minimally pre-processed closed eyes resting-state recording from one of 64 channels of 11 participants of a previously recorded study (#cite(<skukies_2020>, form: "author"), #cite(<skukies_2020>, form: "year")\; for specifics on the preprocessing see appendix @NoiseAp). Additionally, since the recordings tended to be shorter than the simulation, recordings were artificially prolonged by repeating the chosen recording until it matched the length of the simulation. After adding the noise, the data were FIR filtered at a -\6db cut-off frequency of 0.5Hz. All simulations were repeated without noise as well, however since the main results did not change, we do not further discuss them here (see appendix @NoNoiseAp for results without noise). Based on experience and the fact that we only minimally process the noise recordings, we judge the noise level to be realistic, and rather on a more noisy level (i.e. low SNR). Additionally, it should be remarked that our simulations pertain to a single subject, but our free-viewing example results are based on a group of subjects, greatly increasing the SNR.

=== Analysis

We analyzed the generated continuous time series using rERP linear deconvolution based on multiple regression. We varied three analysis parameters: overlap correction (yes/no), modeling duration (simple averaging vs. to model duration), and type of duration-modeling (four different approaches to model duration, see below), effectively forming a 5x2 design of analyses. However, the classical averaging was only calculated in order to compare duration modeling to the current standard practice of not modeling duration at all, as such we show all results relative to the classical averaged ERP (Wilkinson Formula: $y ~ 1$), which ultimately left us with a 4x2 design (overlap correction x type-of-model).

For the first approach, we introduce a linear duration effect to model duration (Wilkinson Formula: $y ~ 1 + italic("dur")$, termed duration-as-linear). 

For the second approach, we binned the event durations into their 10 quantiles, and estimated a separate ERP for each of them, (Wilkinson Formula: $y ~ 1 + italic("bin"("dur"))$, termed duration-as-categorical). This was done as it, at first sight, is a simple solution to modeling varying event durations, even though it is heavily criticized by in the statistics community as “dichotomania” @greenland_2017, and especially in pharmaceutics and the medical field @giannoni.etal_2014 @senn_2005. In our case, we introduce arbitrary bins, and thus unrealistic discontinuities at the event duration bin edges. Yet, this practice has previously been presented as a favorable analysis over classical ERP averaging, and leading to an increase in power @poli.etal_2010.

Third and fourth, we make use of the generalized additive modeling framework (GAM) and use a regression B-spline with two different levels of model flexibility (Wilkinson Formula: $y ~ 1 + italic("spline"("dur", "df"=5))$, and more flexibly: $y ~ 1 + italic("spline"("dur", "df"=10))$, termed duration-as-5spline and duration-as-10spline). 

While a few model estimations were evaluated qualitatively by plotting their time courses (@Quali), the full set of simulations was evaluated by computing the mean squared error (MSE) between the respective model predictions and the ground truth at the 15 quantiles of the duration predictors. Subsequently, MSE values were normalized against the model with no duration effect, that is, the classical averaged ERP. This means that resulting normalized MSE values < 1 indicated that a model was performing better than classical averaging, while values > 1 indicated worse performance.
Additionally to the five modeling approaches, we tested the influence of actively modeling overlap using linear deconvolution using the FIR-deconvolution approach popularized through fMRI @ehinger.dimigen_2019 @smith.kutas_2015a, against the passive method to try to resolve overlap via the duration coefficients @nikolaev.etal_2023.

The above procedure, i.e. every possible parameter combination, was repeated 50 times, resulting in a total of \~15.000 simulations.

Given that statistical precision can be arbitrarily increased by increasing the number of simulations, we opted to forgo statistical analysis of the simulation results entirely. We further do not report any mean MSE values, as we found them quite dependent on initial conditions and less relevant compared to the qualitative results visible. As such, we only consider conditions that are obviously different, e.g., by non-overlapping boxplots as of interest.


== Results

We simulated ERPs with varying event durations and tried to recover the simulation kernel using four different modeling strategies: duration-as-linear, duration-as-categorical, duration-as-5splines, and duration-as-10splines. 

In @Quali, we show a representative analysis of one such simulation, using the scaled hanning shape, realistic noise, and overlap between subsequent events. Two results immediately spring to mind here, foreshadowing our later quantified conclusions:

1) The overall best recovery of the simulation kernel is achieved in the lower row, first panel from the right, the duration-as-10 splines predictor.

2) Comparing the top and bottom rows, without and with overlap correction, shows that only with overlap correction we can get close to recovering the original shape. Thus, purely modeling duration effects, cannot replace overlap correction.

#figure(
  image("assets/20241119QualiResultsScaledHanning.svg", width: 100%),
  caption: [Results from a single simulation for the four tested models (including duration as: linear, categorical, 5-spline, 10-spline variable) combined with (bottom row) and without (top row) overlap correction. Bottom row legend = ground truth. Simulation parameters: shape = scaled hanning; duration simulated = true; distribution = half-normal; noise = true; overlap = true],
) <Quali>

However, it is important to keep in mind that this is only a single simulation. To generalize and quantify these potential effects, we calculated the mean squared error (MSE) between each analysis method's predictions and the ground truth, at 15 different event durations. All resulting MSE values are finally normalized to the results of fitting only a single ERP to all events (Wilkinson notation: $y ~ 1$), that is, modeling no duration effect at all (@MainResults).

#figure(
  image("assets/20241121ResultsFigure.svg", width: 100%),
  caption: [Normalized mean squared error results for the four tested models (including duration as: linear, categorical, 5-spline, 10-spline variable) in different simulation settings. Black line (y-value one) indicated results from classical averaging; MSE of zero indicated perfect estimation of the ground truth. (A) Results when a duration effect,  but no overlap is simulated. The spline strategies outperform the other strategies. (B) Results when no duration effect and no overlap were simulated, but duration effects were still estimated. Little overfit is visible here. (C) Results when duration effects were simulated, signals overlap, and overlap correction was used for modeling. No interaction between duration modeling and overlap correction was observed on the MSE performance. (D) Results when duration effect was not simulated, and signals overlap, and results are overlap corrected.],
)<MainResults>

In the following, we will present the results of the four different simulation settings, modifying both, whether we simulate overlap and duration effects, but also whether we use overlap correction in the analyses. To keep things (relatively) simple, we will first present these results by looking at simulations from only one shape (scaled hanning, see @Methods\.A) and one duration sample distribution (half normal). However, the general conclusions hold true regardless of shape and sampling distribution, as discussed later.

=== The Best Suited Way to Model Duration Effects

First, we simulated duration effects without any overlap and analyzed them using several duration-modeling approaches to investigate their performance compared to not modeling the duration at all (equivalent to a single averaged ERP). @MainResults\.A shows the smallest relative MSE for the spline basis with 5 or 10 splines. This indicates, foremost, that modeling duration effects is superior to not modeling it, but also shows that using splines to model duration effects is superior to using a linear or categorical duration predictors.

To check for potential overfit, we repeated the simulation without simulating any duration effect, where the normalizing (classical averaging) model should perform best. Indeed, this is visible in @MainResults\.B, and, as expected with a more flexible model, we also see a small indication of overfit in the linear and non-linear model fits, but importantly with a negligible size.

Taken together, the drawback of slight overfit in cases with no duration effect is in no relation compared to the benefit of being able to capture the variability a duration effect can introduce.

=== Can we Model Duration Effects and Overlap Simultaneously? <results>

Next, we will introduce overlap between events, mimicking the process of a response ERP following a stimulus ERP, or more appropriate to our simulation setup, subsequent overlapping FRPs in a co-registered EEG/ET experiment. Given that shorter event durations always co-occur with more overlap, and the event distance describes both event durations and overlap, it is not apriori clear whether both can be disentangled simultaneously.

In the case of simulating duration and overlap, and analyzing with overlap correction (@MainResults\.C), we again find the result that duration-as-splines performs best. Indeed, even in our high-noise regime, the more flexible spline conditions outperform the others, without showing higher variance. This is direct evidence that overlap correction and duration-effect modeling can be used concurrently, even though the amount of overlap and the duration effect is strongly correlated by design and in nature.

Additionally, even in cases where ERPs overlap and we would wrongly assume an effect of duration (i.e., modeling duration, while no duration effect is present in the data) model performance only slightly decreases when we correct for the overlap (@MainResults\.D) compared to cases where no overlap is present (@MainResults\.B). This indicates that, while researchers should still carefully consider if an effect of duration is present in their data, the potential drawbacks of not modeling an existing duration effect are far greater than the opposite.

=== Can we model Overlap via Duration Effects?

#cite(<nikolaev.etal_2016>, form: "prose") and #cite(<vanhumbeeck.etal_2018>, form: "prose") raised the idea that overlap effects can be taken into account, using only non-linear splines for the duration predictor, but never explicitly tested this in simulations. As visible in @Quali (compare overlap corrected and not overlap corrected), this seems to be insufficient. We tested this more systematically (depicted in XXX), and in fact, in our simulations, a model without any overlap correction even outperforms modeling overlap via duration. This shows us that we indeed have to, and can, rely on other techniques like linear deconvolution, as proposed in this study.

=== Influence of Shape and Overlap Distribution

There are two more parameters of our simulations that we have not yet presented: the overall shape of the ERP (not only the duration part), and the distribution of durations (and with that, overlap). The overall main conclusions hold true regardless of the set parameters.

#figure(
  image("assets/20241121ShapeDistributionEffect.svg", width: 100%),
  caption: [Comparison of normalized mean squared error results for the four tested models (including duration as: linear, categorical, 5-spline, 10-spline variable) between shapes (A-C) and duration distributions (color pairs). The Black line (y-value one) indicates results from classical averaging; A MSE of zero indicates perfect estimation of the ground truth. Parameter settings for all panels: duration affects shape; overlap simulated; overlap corrected/ modeled.],
)<DistResults>

Regardless of the shape of the simulated proto-ERP and overlap distribution, spline-modeling of duration consistently gives us the best results (@DistResults\.A-C). However, MSE values and variance increase for the hanning shape (relative to the scaled hanning), and even further for the half hanning shape. Importantly, for the latter, variance in MSE values increased in a way, that for some simulation instances (i.e., for specific seeds) it would have been better to not model duration at all. We think that this increase in variance and value of MSE for the half hanning shape might be due to a saturation effect; if there is less variance in the duration effect to be explained in the first place, then a model without duration effect might perform similarly to a model explicitly modeling it. Lastly, we do not observe a consistent pattern of the influence of the distribution of overlap, but we cannot exclude more extreme choices (@DistResults color pairs).

=== The Necessity of Block Experimental Structures <block>

In our initial simulation of duration combined with overlap correction, we noticed strong structured noise patterns. This pattern persisted even when no signal was simulated (@BlockResults\.B), and it completely disappeared when event timings from real datasets were used. We systematically tested different potential sources and found that the block structure of most experiments, that is, having a break after a set of events (@BlockResults\.A lower) resolves this issue. Note that this is not specific to one modeling strategy, but rather the artefact (@BlockResults\.B) can appear even with a linear effect. We quantitatively tested this finding and show that artificially introducing a break after every 25 events (which results in only 20 breaks in our simulations) completely removes this artefact (@BlockResults\.B vs. @BlockResults\.C, @BlockResults\.D). 

#figure(
  image("assets/20241119BlockFigure.svg", width: 100%),
  caption: [Comparison of simulations with and without simulated block structure. Up left: Ground truth shape “half hanning” used in the depicted simulation; (A) Continuous simulated EEG and its underlying responses without noise, once without (up), and once with (down) added blocks ; (B) Estimates from one simulation without added blocks, once without any signal in the data (left, i.e. the data contained only noise) and once with added signals (right, i.e. the data contained noise + signal); (C) Estimates from the same simulation, but with added blocks every 25 events, once without any signal in the data (left, i.e. the data contained only noise) and once with added signals (right, i.e. the data contained noise + signal); (D) Comparison of MSE results between simulations with blocks added (full colors) and simulations without any blocks added (cross-hatched colors) for all tested models in conjunction with overlap correction.],
)<BlockResults>

We assume that when including the inter-event distance both as a predictor, but also explicitly in the FIR time-expanded designmatrix, leads to a specific type of collinearity. This collinearity “blows up” the model estimates, and due to the duration effect, results in smooth wave-like patterns (@BlockResults\.B). When introducing (seemingly) overlap-free events at the beginning and end of a block, this collinearity between the duration and the structure of the designmatrix is broken, and a “unique” solution can be estimated.

#pagebreak()

= Real Data Example: EEG + ET

We move our eyes approximately 120-240 times each minute. Besides being an interesting behavior in itself, eye movements offer a unique and data-rich segmentation event for EEG. Consequently, more and more researchers use EEG and eyetracking to better understand human cognition @dimigen.etal_2014 @dimigen.ehinger_2021 @nikolaev.etal_2016. Here, EEG and eye movements are co-registered, such that single fixation can be used as event markers in the EEG. These fixations can then be assigned to different conditions based on the fixated stimulus, and modeled accordingly to achieve a fixation-related potential.

To illustrate the interplay of duration and overlap modeling, we make use of a public co-registered unrestricted viewing dataset by #cite(<gert.etal_2022>, form: "prose"). 

== Methods

The data by #cite(<gert.etal_2022>, form: "prose") was already preprocessed as follows: First, the eyetracking and EEG data were integrated and synchronized using the EYE-EEG toolbox (http://www2.hu-berlin.de/eyetracking-eeg) @dimigen.etal_2014. Next, the data was down-sampled from 1024 Hz to 512 Hz and high-pass filtered at 1Hz (-6 db cutoff at .5 Hz). Muscle artifacts and noisy channels were manually inspected and marked or removed respectively. Subsequently, ICA was computed, and artefactual components were subtracted. Lastly, the data was re-referenced to an average reference and removed channels were interpolated through spherical interpolation. For more specifics on the preprocessing, please see #cite(<gert.etal_2022>, form: "prose").

To showcase our approach, we then calculated fixation-related potentials (FRP) using custom scripts and the Unfold.jl toolbox @ehinger.alday_2024. The data was modeled with linear models following the Wilkinson notation: 

$ italic("y_fixation") ~ & 1 + \ 
  & italic("is_face") + \
  & italic("spl"("duration", 4)) + \
  & italic("spl"("sac_amplitude", 4)) + \ 
  & italic("spl"("fix_avgpos_x", 4)) + \ 
  & italic("spl"("fix_avgpos_y", 4)) $


Where _if_face_ represents whether in that fixation a face was fixated (yes/no), _duration_ the fixation duration; _sc_amplitude_ the saccade amplitude; _fix_avgpos_x_ & _fix_avgpos_x_  the average x- and y-position of the current fixation. Next to fixation duration, we incorporated the other covariates in the analysis as they are known to have an influence on the FRP @gert.etal_2022 @nikolaev.etal_2023, and we wanted to adjust for these factors when investigating fixation duration. Additionally, stimulus onsets were modeled using a 
$ italic("y_stimulus") ~ 1 $
formula, as the onset of a stimulus can have huge overlapping effects on subsequent fixations @coco.etal_2020 @dimigen.ehinger_2021 @gert.etal_2022.

As in our simulations, the model was calculated once with, and once without overlap correction. Because we were only interested in the effect of duration, we then calculated marginalized effects of duration on the ERP, while holding all other covariates constant at their respective means.

Finally, we statistically tested for the duration effect with and without overlap, and for the difference of the duration effect between with and without modeling. As proposed in #cite(<pernet.etal_2011>, form: "prose"), we use a Hotelling T² test (implemented in HypothesisTests.jl v0.11.0), but on the spline coefficients to test them against the null hypothesis of all coefficients being 0 across subjects. We subsequently calculate a Benjamini-Yekutieli, via MultipleTesting.jl @benjamini.yekutieli_2001 @gehring.etal_2023), false discovery rate correction over all channels and time points to address the multiple comparison problem. To test the difference, we  tested the difference of the maximal marginal effects (calculation described below) of without and with deconvolution using an FDR corrected one sample t-test.

For visualization, we estimate marginal effects over a range of durations (-0.1 to 1s).
To visualize our results in a topoplot series @mikheev.etal_2024a, we break down the multi-parameter spline estimate to a single value per channel and time-point, we calculate the maximal marginal effect over the range of durations calculated before. This quantity is positively biased (the maximum needs to be >0). We therefore decided to test the coefficients directly (as described above), rather than this visualization. This has the unfortunate effect, that in some cases, what is tested, is not the same as what is visualized, the reason being the lack of visualization tools for non-linear effects. Only for the difference do visualization and test directly correspond to each other. We used the UnfoldMakie.jl @mikheev.etal_2024b and Makie.jl @DanischKrumbiegel2021 libraries for visualization.

== Results

As indicated in @AppliedResuts, without overlap correction we find three clusters of fixation duration effects along the midline: over frontal, occipital and centro-parietal electrodes.

However, when modeling overlap in addition to duration, we found duration effects to become smaller and even vanish. This indicates, as proposed by #cite(<nikolaev.etal_2016>, form: "prose"), that a duration predictor tries to compensate for the overlap (but ultimately fails to do so; see simulation results @results). Yet, an effect over central electrodes at around 0.450 s. after fixation onset still persists in the results after overlap correction (@AppliedResuts). This is direct evidence for the existence of event duration effects in EEG-eye-tracking co-registered data.

#figure(
  image("assets/figure2_unfoldduration.svg", width: 100%),
  caption: [Results from a free viewing experiment. A) Regression FRPs with marginal effects of fixation duration from channels AFz [left], Cz [middle], and Oz [right], once without [up] and once with [bottom] overlap correction. B) Topoplots for results without overlap correction [up], with overlap correction [middle], and the difference between with and without overlap correction [bottom]; Displayed values are the maximal difference between two evaluated marginal effects (i.e. the maximal difference between any line in A), whereas significantly marked channels were evaluated using a Hotelling-t#super[2] test of the non-linear spline coefficients, which can lead to discrepancies of highest activity and significance. The significance of the difference was tested with mass-univariate one-sample t-tests, and corrected for multiple comparisons using FDR. We plot a marker, if the minimal corrected p-value in a time window is below 0.05 and weight the size logarithmically according to the p-value (that is, larger markers indicate smaller p-values).],
)<AppliedResuts>

#pagebreak()

= Discussion

Event durations often differ between conditions and participants. While in some cases this can be controlled, in many cases it cannot. As soon as the event duration is under the control of the subject (e.g., differing reaction times in old vs. young, or with the recent experimental trends towards quasi-experimental designs), many aspects of an experiment are no longer under the control of the experimenter. Here, we first show that such a discrepancy can lead to spurious effects in the estimated brain responses. We next demonstrate that when explicitly modeling such event duration effects, these spurious effects can be successfully addressed. Finally, we systematically evaluated that non-linear modeling of event durations is compatible with linear overlap correction and that implementing such analysis can give a better understanding of the true brain processes. 

== Modeling Event Durations

One of the key takeaways from our study is the potential for spurious effects in neural data analysis results when variations in event durations are not considered. This is in line with research by #cite(<wang.etal_2018>, form: "prose") which showed that neural activity can scale in proportion to task duration, and #cite(<yarkoni.etal_2009>, form: "prose") and #cite(<mumford.etal_2023a>, form: "prose"), that argued for including durations during modeling of fMRI data.

In EEG research, earlier studies proposed to circumvent this problem by binning reaction times and calculating the average ERP of each bin @poli.etal_2010 (and is now a prominent suggested method in ERP analysis; see the chapter on event bins in #cite(<luck_2022>, form: "author"), #cite(<luck_2022>, form: "year")) or as a non-linear predictor via a smoothing function @vanhumbeeck.etal_2018 @hassall.etal_2022. Contrary to what the issue of “dichotomania” @senn_2005 might suggest at first sight, our simulations show that categorizing durations into bins performs better than even linear modeling of duration. This is a result of the underlying event duration effect not being linear but rather non-linear. Summarized, while binning is able to improve results over not modeling and linear modeling, it does so by introducing unrealistic discontinuities which can be remedied by using splines. 

We show the critical role that duration plays in the interpretation of ERP results, and further, that it takes the flexibility of non-linear spline estimation via multiple regression to model event durations and achieve meaningful results. As such, to ensure accuracy and reliability of results, duration effects cannot be ignored, but rather must be addressed.

== Compatibility with Linear Overlap Correction

The presence of overlap in EEG data is a common phenomenon. And although this problem  has been thoroughly addressed before @ehinger.dimigen_2019 @smith.kutas_2015, it was not clear if modeling of event durations and overlap correction can be combined. That is, through a dependence of varying-event timings needed for linear deconvolution, which in turn are directly related to the duration effect, we were left with a potential collinearity problem.

Our simulations indicate that non-linear event duration modeling and linear deconvolution of adjacent events (i.e. overlap correction) can be seamlessly integrated. We also showed that this comes at a minimal cost in terms of potential overfit, should there be no ground truth duration effect in the data. We therefore recommend using our proposed non-linear duration modeling in cases researchers suspect effects of duration.

== Further Considerations

In addition to overlap and duration estimation method, we considered four further parameters: ERP shape, block-design, jittering inter-onset distances, and regularization.

- #underline[ERP shape]: Overall, results do not change drastically based on different ERP shapes, i.e. it is still best to model duration by non-linear spline modeling in conjunction with overlap correction. However, while results from two of our used shapes (scaled hanning and hanning) showed very similar results, the half hanning shape showed signs of increased overfit for 10-splines, with larger MSE compared to the best-performing 5-splines. Currently, the number of splines in overlap-corrected regression fits has to be chosen by hand, instead of an automatic penalized splines method due to computational reasons. Similarly, the variability of MSE values within model categories increased, especially for the more flexible models. This is likely due to the shorter time window of the duration effect itself, and thus these flexible models are more prone to overfit on the noise in the earlier non-changing part of the shape. We cannot exclude more extreme shapes to show more extreme behavior.

- #underline[Block-design]: As described in @block, a continuous stream of overlapping events without breaks leads to increased overfit under certain simulation conditions. Introducing “inter-block intervals”, where at least two adjacent events break the homogeneous overlap-duration relationship, alleviates this issue. We think that such pauses break the correlation between inter-event onsets as modeled with the FIR time expansion, and the duration predictor. Further simulations showed that this effect is not specific to splines, but also occurs with linear duration modeling. Further, this effect is irrespective of shape and occurs in pure noise data as well (see @BlockResults). However, by adding only one or more (depending on SNR) of the aforementioned inter-block intervals, we could resolve this noise amplification.

 In real data such inter-block intervals can occur, for example in free-viewing experiments where FRPs are of interest. Here, while fixation duration and overlap are indeed perfectly correlated within the e.g. 5s of looking at a stimulus, the last fixation before removing the stimulus does have a duration, but no further (modeled) fixation overlapping. In other experiments, blocks can (and usually are) in the experiment by design.

- #underline[Jittering inter-onset-distances]: In our free viewing data, we also noticed that the inter-event onsets and durations are not as perfectly correlated as in our simulation due to variable saccade duration. We therefore introduced  a uniform jitter of +-30ms (expected saccade duration) to the inter-event-onsets in some exploratory simulations. This had only a minimal effect, if any at all, in these simulations. We did not test this systematically, as it is outside the scope of this paper.

- #underline[Regularization]: Lastly, we also ran some preliminary tests on L2 regularization @kristensen.etal_2017. Regularization should reduce overfit on the data at the expense of introducing a bias, in the case of the L2 norm, towards coefficients with smaller amplitude. Typically, the amount of regularization is chosen by cross-validation, however, in our simulations, we often observed that this resulted in regularization to (near) zero. Currently, in Unfold only a “naive” cross-validation within the cvGLMNET solver @qian.etal_2013 is available. This method is insufficient solely because that cross-validation breaks are automatically set by a blackbox-function, and thus can be within-blocks, potentially leading to data leakage between test and validation set. We are not aware of a sufficient implementation alleviating this. Nevertheless, we identified a second, more severe limitation than data leakage: There is only a single regularization parameter for the whole model, thus with overlap correction, we regularize all time points relative to an event onset equally. This means, that baseline periods, where the true regularization coefficient should be very high, as there is no reliable time-locked activity wash over to periods of activity, greatly reducing their amplitude, often to zero. Setting the regularization parameter by hand, as expected, leads to a strong reduction of this noise artefact, but at the cost of bias. Only more nuanced applications of regularization can fully address this issue, and more work is needed.

== Limitations

=== Limitations of our Simulations

In this study, we focused on three rather simple shapes for simplicity's sake. These three shapes cover a range of possible changes to the shape in that they stretch in time, both in time and amplitude, or only partly, which are simplifications of real examples @hassall.etal_2022 @wang.etal_2018. However, although earlier simulations with more complicated shapes that included multiple positive and negative peaks showed no substantial differences in results, we cannot be certain how our results generalize to all possible shapes.

Furthermore, our study is in several cases limited to relative comparisons between analysis methods, where the spline-modeling performed best. This does not mean that it ultimately recovers the underlying shape perfectly. Indeed, inspecting @Quali, one can clearly see that the pattern is not an exact recovery, but confounded by noise - still, it is performing much better than ignoring the issue and only using a single ERP. Similarly, we use only a single measure (MSE) to evaluate and delineate the different analysis methods, other choices of measures are possible (e.g. correlation, absolute error, removal of baseline period). We do not expect qualitatively different results.

Next, we did not investigate if there are interactions between a condition effect and the duration effect. That is, throughout the paper, we assume that the duration effect is the same in all conditions. If we allow for such an interaction, then it is unclear to us, if these per-condition-duration-effects could be used to explain the main effects of conditions as well. 

Additionally, our simulation study covers a large area of simulation parameters, but cannot cover all possible cases. Indeed, some interesting variations could be to introduce continuous and categorical condition differences, incorporate multiple event types, use more flexible non-linear analysis methods (e.g. DeepRecurrentEncoder @chehab.etal_2022) or try to simulate empirically observed duration effects more realistically.

Lastly, we had a coarse look at different noise levels (unreported), and two noise types (white and real noise). Both factors did not influence our conclusions or the relative order of the methods.

=== Limitations of Results

Another clear limitation of our study is, that we only look at model performance of what essentially constitutes results from a single subject. In this paper, we do not address how the performance will improve if estimates over multiple subjects are aggregated. In the applied example, we average results over multiple subjects, but here we want to highlight a potential caveat relating to spline modeling in general: Experimenters need to decide whether to normalize durations per subject, effectively modeling quantiles over subjects, or assume that ERPs relate better to absolute durations. Because knot placement and coverage of splines depend on the distribution of each single subject, not all subjects have the same  smoothing factor. Interested readers are pointed to @wood_2017 for a discussion of these issues. 

A more general limitation is, that we cannot know how such duration effects are implemented in the brain. This could potentially lead to an issue of causality, as the duration covariate is used to explain points in time at which the system has not yet actually specified the event duration. This limitation is not specific to this study, but in general whenever e.g. reaction times, or even behavioral responses are used to predict neural data.

Lastly, the performance of our method compared to the approach by #cite(<hassall.etal_2022>, form: "prose") remains to be shown. They assume a single response is stretched in time, setting a strong prior on the possible relation. Such a relation would be fulfilled in our simulation for the stretched hanning window, but not in the other shapes.


== Generalization to other Modalities

While in this paper, we focus on applying our approach to M/EEG data, it can be extended to other neuroimaging techniques. In fact, it is plausible that almost all brain time series analyses could benefit from considering event duration as a potential confounder.

The first technique that comes to mind is functional magnetic resonance imaging (fMRI). fMRI has the advantage that the underlying measure generator is relatively well understood (as the hemodynamic response function; HRF). As such, the problem of overlapping signals has been thoroughly addressed @penny.etal_2011. Yet, a change in the HRF due to a different event duration is rarely considered. Some studies have shown the importance of modeling reaction times in fMRI studies @mumford.etal_2023a @yarkoni.etal_2009, however, the authors modeled reaction time as a linear predictor rather than non-linear as indicated by our study. Further, both studies only focus on reaction time, whereas we argue to generalize such modeling to other event durations, such as stimulus durations or fixation durations.

Another technique where our approach should prove useful is the investigation of local field potentials (LFP). This should come as no surprise, as LFP are inherently very close in analysis to EEG. That is, LFPs consist of fast-paced electrical fields which might overlap in time and are likely subject to change depending on the length of an event. In fact, at least one study in non-human primates already highlighted the relationship between task timing and LFPs @kilavik.etal_2010. However, their task involved the primates to execute a limb movement of one of two interval lengths, over which was then aggregated, instead of considering duration as a continuous predictor. Additionally, overlap was not considered.

Lastly, pupil dilation measurements could benefit from our analysis approach as well. Typically, pupil dilation is taken as an indirect measurement of arousal states, cognitive load, and has been linked to changes in the noradrenergic system @larsen.waters_2018. Whereas pupil dilation has often been related to reaction time @hershman.henik_2019 @isabella.etal_2019 @strauch.etal_2020, none have modeled reaction time explicitly. At least one theory-driven model has been proposed which offers explanations for a wider range of parameters, including trial duration @burlingham.etal_2022. However, again overlapping signals are dismissed in this model, as such our more general approach is to be preferred.

= Summary

In the present study, we show through extensive simulations that event durations can and should be modeled in conjunction with overlap correction. Through combining linear overlap correction with non-linear event duration modeling, researchers gain a more powerful tool set to better understand human cognition. Overlap correction disentangles the true underlying signals of the ERPs, while event duration modeling can lead to a more nuanced understanding of the neural responses. 

By applying this analysis to real data, we underscore the importance of modeling event durations both, in cases where they are of interest themselves, as well as in situations where durations may have an interfering influence on the results. 

As such, we advise researchers who study human time series data to take special care to consider if and how overlap and event durations affect their data.

#set heading(numbering: none)

= Conflicts of Interest

The authors have no conflicts of interest to declare. All co-authors have seen and agree with the contents of the manuscript, and there is no financial interest to report.

= Data and Code Availability

All code is publicly available at https://github.com/s-ccs/unfold_duration. The FRP data can be obtained from Gert et al. (2022). 

= Author Contributions

- #underline[René Skukies]: Conceptualization; Methodology; Software; Formal analysis (simulations); Data Curation; Writing - Original Draft; Visualization

- #underline[Judith Schepers]: Formal analysis (FRP analysis); Writing - Review & Editing

- #underline[Benedikt Ehinger]: Conceptualization; Methodology; Software; Resources; Supervision; Formal analysis(simulations, FRP analysis); Writing - Review & Editing; Visualization; Funding acquisition

= Funding

Funded by Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) under Germany's Excellence Strategy - EXC 2075 – 390740016. We acknowledge the support by the Stuttgart Center for Simulation Science (SimTech). The authors further thank the International Max Planck Research School for Intelligent Systems (IMPRS-IS) for supporting Judith Schepers.

#set par(justify: true, first-line-indent: 0pt);

#bibliography(title:"Bibliography", style:"american-psychological-association", "2024UnfoldDuration.bib")

#show: arkheion-appendices
=

== Noise Preprocessing <NoiseAp>

Eyes closed resting state data was preprocessed as follows

1. Data was down-sampled to 500Hz
2. EEGLAB's `pop_clean_rawdata()` was used to reject bad channels using Parameters: `FlatlineCriterion = 5`; `ChannelCriterion = 0.8`; `LineNoiseCriterion = 4`; `Highpass = [0.25, 0.75]`
3. Data was re-referenced to average reference
4. A copy of the data was made, and the copy was high-pass filtered at 1.5Hz
5. ICA was calculated on the (filtered) copied data
6. Bad components were marked using ICLabel with Parameters only set for eye movements and muscle artefacts (i.e. only eye- and muscle-artefacts were rejected)
7. ICA weights and reject-markers were copied to original data and bad components were subtracted
8. Rejected channels were interpolated via spherical interpolation

Additionally, during simulations the data was down-sampled (default 100Hz) and high-pass filtered (default 0.5 Hz) to match the simulations.

#pagebreak()
== No Noise Results <NoNoiseAp>

#figure(
  image("assets/20241121ResultsFigure_noNoise.svg", width: 100%),
  caption: [Normalized mean squared error results for the four tested models (including duration as: linear, categorical, 5-spline, 10-spline variable) in different simulation settings without added noise. Black line (y-value one) indicated results from classical averaging; MSE of zero indicated perfect estimation of the ground truth. (A) Results when a duration effect,  but no overlap is simulated. The spline strategies outperform the other strategies. (B) Results when no duration effect and no overlap were simulated, but duration effects were still estimated. Little overfit is visible here. (C) Results when duration effects were simulated, and signals overlap, and overlap correction is used for modeling. No interaction between duration modeling and overlap correction was observed on the MSE performance. (D) Results when duration was not simulated, and signals overlap.],
)

#figure(
  image("assets/20240923ShapeDistributionEffectNoNoise_B.svg", width: 100%),
  caption: [Normalized mean squared error results for the four tested models in simulations without noise (including duration as: linear, categorical, 5-spline, 10-spline variable) between shapes (A-C) and duration distributions (color pairs). Black line (y-value one) indicated results from classical averaging; MSE of zero indicated perfect estimation of the ground truth. Parameter settings for all panels: duration affects shape; overlap simulated; overlap corrected/ modeled.],
)

#pagebreak()
== Duration Modeling vs. Overlap Correction <DurModVSOC>

#figure(
  image("assets/20241121_DurationModelling_vs_OverlapCorrection.svg", width: 100%),
  caption: [Normalized mean squared error results for the four tested models in simulations without noise (including duration as: linear, categorical, 5-spline, 10-spline variable) between shapes (A-C) and duration distributions (color pairs). Black line (y-value one) indicated results from classical averaging; MSE of zero indicated perfect estimation of the ground truth. Parameter settings for all panels: duration affects shape; overlap simulated; overlap corrected/ modeled.],
)
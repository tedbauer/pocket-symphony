port module Main exposing (..)

import Browser
import ControlBar
import Delay
import DrumMachine
import Envelope
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onMouseDown)
import Lfo
import Oscillator
import Platform.Cmd as Cmd
import Sequencer


type alias Model =
    { controlBar : ControlBar.Model
    , sequencer : Sequencer.Model
    , drumMachine : DrumMachine.Model
    , lfo : Lfo.Model
    , envelope : Envelope.Model
    , delay : Delay.Model
    , oscillator : Oscillator.Model
    }



-- MODEL


init : () -> ( Model, Cmd Msg )
init _ =
    ( { controlBar = ControlBar.init
      , sequencer = Sequencer.init
      , drumMachine = DrumMachine.init
      , lfo = Lfo.init
      , envelope = Envelope.init
      , delay = Delay.init
      , oscillator = Oscillator.init
      }
    , Cmd.none
    )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "root" ]
        [ div [ class "cardrows" ]
            [ div [ class "cardrow" ]
                [ Html.map ControlBarMsg (ControlBar.view model.controlBar)
                ]
            , div [ class "cardrow" ]
                [ Html.map SequencerMsg (Sequencer.view model.sequencer)
                , Html.map EnvelopeMsg
                    (Envelope.view model.envelope)
                , Html.map
                    OscillatorMsg
                    (Oscillator.view model.oscillator)
                ]
            , div [ class "cardrow" ]
                [ Html.map LfoMsg (Lfo.view model.lfo)
                , Html.map DelayMsg (Delay.view model.delay)
                , Html.map DrumMachineMsg (DrumMachine.view model.drumMachine)
                ]
            , div [ class "cardrow" ]
                [ div [ class "cardnofill" ]
                    [ div [ class "parambutton" ] [ a [ href "https://github.com/tedbauer/sequencer/issues/new/choose" ] [ text "Report an issue" ] ]
                    ]
                , div [ class "cardnofill" ] [ div [ class "parambutton" ] [ a [ href "https://polarbeardomestication.net" ] [ text "polarbeardomestication.net" ] ] ]
                ]
            ]
        ]



-- UPDATE


type Msg
    = SetCurrentStep Int
    | ControlBarMsg ControlBar.Msg
    | SequencerMsg Sequencer.Msg
    | DrumMachineMsg DrumMachine.Msg
    | EnvelopeMsg Envelope.Msg
    | LfoMsg Lfo.Msg
    | DelayMsg Delay.Msg
    | OscillatorMsg Oscillator.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetCurrentStep step ->
            let
                ( updatedDrumMachine, _ ) =
                    DrumMachine.update (DrumMachine.SetCurrentStep step) model.drumMachine

                ( updatedSequencer, _ ) =
                    Sequencer.update (Sequencer.SetCurrentStep step) model.sequencer

                ( updatedControlBar, _ ) =
                    ControlBar.update (ControlBar.SetCurrentStep step) model.controlBar
            in
            ( { model | drumMachine = updatedDrumMachine, sequencer = updatedSequencer, controlBar = updatedControlBar }, Cmd.none )

        ControlBarMsg controlBarMsg ->
            let
                ( subModel, subCmd ) =
                    ControlBar.update controlBarMsg model.controlBar
            in
            let
                ( updatedSequencer, _ ) =
                    Sequencer.update (Sequencer.SetCurrentStep subModel.activeStep) model.sequencer
            in
            let
                ( updatedDrumMachine, _ ) =
                    DrumMachine.update (DrumMachine.SetCurrentStep subModel.activeStep) model.drumMachine
            in
            ( { model | controlBar = subModel, sequencer = updatedSequencer, drumMachine = updatedDrumMachine }, Cmd.map ControlBarMsg subCmd )

        DrumMachineMsg drumMachineMsg ->
            let
                ( subModel, subCmd ) =
                    DrumMachine.update drumMachineMsg model.drumMachine
            in
            ( { model | drumMachine = subModel }, Cmd.map DrumMachineMsg subCmd )

        SequencerMsg sequencerMsg ->
            let
                ( subModel, subCmd ) =
                    Sequencer.update sequencerMsg model.sequencer
            in
            ( { model | sequencer = subModel }, Cmd.map SequencerMsg subCmd )

        LfoMsg lfoMsg ->
            let
                ( subModel, subCmd ) =
                    Lfo.update lfoMsg model.lfo
            in
            ( { model | lfo = subModel }, Cmd.map LfoMsg subCmd )

        EnvelopeMsg envelopeMsg ->
            let
                ( subModel, subCmd ) =
                    Envelope.update envelopeMsg model.envelope
            in
            ( { model | envelope = subModel }, Cmd.map EnvelopeMsg subCmd )

        DelayMsg delayMsg ->
            let
                ( subModel, subCmd ) =
                    Delay.update delayMsg model.delay
            in
            ( { model | delay = subModel }, Cmd.map DelayMsg subCmd )

        OscillatorMsg oscillatorMsg ->
            let
                ( subModel, subCmd ) =
                    Oscillator.update oscillatorMsg model.oscillator
            in
            ( { model | oscillator = subModel }, Cmd.map OscillatorMsg subCmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveCurrentStepUpdate SetCurrentStep
        , Sub.map ControlBarMsg (ControlBar.subscriptions model.controlBar)
        , Sub.map EnvelopeMsg (Envelope.subscriptions model.envelope)
        , Sub.map LfoMsg (Lfo.subscriptions model.lfo)
        , Sub.map DelayMsg (Delay.subscriptions model.delay)
        , Sub.map OscillatorMsg (Oscillator.subscriptions model.oscillator)
        ]



-- PORTS


port receiveCurrentStepUpdate : (Int -> msg) -> Sub msg



-- MAIN


main =
    Browser.element { init = init, subscriptions = subscriptions, update = update, view = view }

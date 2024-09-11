module Oscillator exposing (..)

import Debug exposing (toString)
import Html exposing (Html, div, option, select, text)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onInput, onMouseDown)
import Knob
import SoundEngineController


type alias Model =
    { waveform : String
    , coarseFrequency : Knob.Model
    , fineFrequency : Knob.Model
    , octave : Int
    }


init : Model
init =
    { waveform = "sine"
    , coarseFrequency = Knob.init 0 0 50 0.1
    , fineFrequency = Knob.init 0 0 50 0.1
    , octave = 0
    }


type Msg
    = SetWaveform String
    | CoarseFrequencyMsg Knob.Msg
    | FineFrequencyMsg Knob.Msg
    | SetOctave Int


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div [ class "cardtitle" ] [ text "🎵 Oscillator" ]
        , div [ class "oscillator" ]
            [ div [ class "oscillator-params" ]
                [ div [ class "osc-wave-selector" ] [ waveformSelector model.waveform ]
                , div [ class "seqctrl" ]
                    [ div [ class "parambutton", onMouseDown (SetOctave (model.octave + 1)) ] [ text "⬆️" ]
                    , div [ class "parambutton", onMouseDown (SetOctave (model.octave - 1)) ] [ text "⬇️" ]
                    , text "Octave: "
                    , text (toString model.octave)
                    ]
                , div [ class "labeledknob-horizontal" ]
                    [ Html.map CoarseFrequencyMsg (Knob.view 30 model.coarseFrequency)
                    , text "Coarse frequency"
                    ]
                , div [ class "labeledknob-horizontal" ]
                    [ Html.map FineFrequencyMsg (Knob.view 30 model.fineFrequency)
                    , text "Fine frequency"
                    ]
                ]
            ]
        ]


waveformSelector : String -> Html Msg
waveformSelector currentWaveform =
    div [ class "waveform-selector" ]
        [ select [ class "wave-type-select", onInput SetWaveform, value currentWaveform ]
            [ option [ value "sine" ] [ text "Sine" ]
            , option [ value "square" ] [ text "Square" ]
            , option [ value "sawtooth" ] [ text "Sawtooth" ]
            , option [ value "triangle" ] [ text "Triangle" ]
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetWaveform waveform ->
            ( { model | waveform = waveform }, SoundEngineController.stepEngine (SoundEngineController.encode_oscillator_waveform waveform) )

        CoarseFrequencyMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.coarseFrequency
            in
            ( { model | coarseFrequency = newKnob }
            , maybeValue |> Maybe.map SoundEngineController.encode_oscillator_coarse_frequency |> Maybe.map SoundEngineController.stepEngine |> Maybe.withDefault Cmd.none
            )

        FineFrequencyMsg knobMsg ->
            let
                ( newKnob, _ ) =
                    Knob.update knobMsg model.fineFrequency
            in
            ( { model | fineFrequency = newKnob }
            , SoundEngineController.stepEngine (SoundEngineController.encode_oscillator_fine_frequency newKnob.value)
            )

        SetOctave octave ->
            ( { model | octave = octave }, SoundEngineController.stepEngine (SoundEngineController.encode_oscillator_octave octave) )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map CoarseFrequencyMsg (Knob.subscriptions model.coarseFrequency)
        , Sub.map FineFrequencyMsg (Knob.subscriptions model.fineFrequency)
        ]

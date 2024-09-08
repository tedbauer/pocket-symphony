module Oscillator exposing (..)

import Debug exposing (toString)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onMouseDown)
import Knob


type alias Model =
    { waveform : String
    , frequency : Knob.Model
    , detune : Knob.Model
    , octave : Int
    }


init : Model
init =
    { waveform = "sine"
    , frequency = Knob.init 440 20 2000 1
    , detune = Knob.init 0 -100 100 1
    , octave = 0
    }


type Msg
    = SetWaveform String
    | FrequencyMsg Knob.Msg
    | DetuneMsg Knob.Msg
    | SetOctave Int


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div [ class "cardtitle" ] [ text "🎵 Oscillator" ]
        , div [ class "oscillator" ]
            [ div [ class "oscillator-params" ]
                [ div [ class "labeledknob-horizontal" ]
                    [ Html.map FrequencyMsg (Knob.view 30 model.frequency)
                    , text "Frequency"
                    ]
                , div [ class "labeledknob-horizontal" ]
                    [ Html.map DetuneMsg (Knob.view 30 model.detune)
                    , text "Detune"
                    ]
                ]
            , div [ class "seqctrl" ]
                [ div [ class "parambutton", onMouseDown (SetOctave (model.octave + 1)) ] [ text "⬆️" ]
                , div [ class "parambutton", onMouseDown (SetOctave (model.octave - 1)) ] [ text "⬇️" ]
                , text "Octave: "
                , text (toString model.octave)
                ]
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetWaveform waveform ->
            ( { model | waveform = waveform }, Cmd.none )

        FrequencyMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.frequency
            in
            ( { model | frequency = newKnob }
            , Cmd.none
              -- You might want to add a port command here
            )

        DetuneMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.detune
            in
            ( { model | detune = newKnob }
            , Cmd.none
              -- You might want to add a port command here
            )

        SetOctave octave ->
            ( { model | octave = octave }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

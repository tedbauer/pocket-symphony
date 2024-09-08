module Lfo exposing (..)

import Html exposing (Html, div, li, option, select, text, ul)
import Html.Attributes exposing (class, height, value, width)
import Html.Events exposing (onInput, onMouseDown)
import Knob
import SoundEngineController
import Svg exposing (line, svg)
import Svg.Attributes


type WaveType
    = Sine
    | Square
    | Sawtooth
    | Triangle


type alias Model =
    { frequency : Knob.Model
    , intensity : Knob.Model
    , waveType : WaveType
    }



-- MODEL


init : Model
init =
    { frequency = Knob.init 1 0 50 0.1
    , intensity = Knob.init 1 0 200 0.1
    , waveType = Sine
    }



-- VIEW


generateWavePoints : Int -> Float -> Float -> WaveType -> String
generateWavePoints width amplitude frequency waveType =
    List.range 0 width
        |> List.map
            (\x ->
                let
                    y =
                        case waveType of
                            Sine ->
                                amplitude * sin (frequency * toFloat x * pi / 180)

                            Square ->
                                if sin (frequency * toFloat x * pi / 180) >= 0 then
                                    amplitude

                                else
                                    -amplitude

                            Sawtooth ->
                                amplitude * (2 * ((frequency * toFloat x / 360) - toFloat (floor (frequency * toFloat x / 360))) - 1)

                            Triangle ->
                                amplitude * (2 * abs (2 * ((frequency * toFloat x / 360) - toFloat (floor (frequency * toFloat x / 360 + 0.5)))) - 1)
                in
                String.fromInt x ++ "," ++ String.fromFloat (100 - y)
            )
        |> String.join " "


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div [ class "cardtitle" ] [ text "〰️ LFO" ]
        , div [ class "lfo" ]
            [ div [ class "graph" ]
                [ svg
                    [ width 100
                    , height 100
                    , Svg.Attributes.viewBox "0 0 400 200"
                    ]
                    [ line
                        [ Svg.Attributes.x1 "0"
                        , Svg.Attributes.y1 "100"
                        , Svg.Attributes.x2 "400"
                        , Svg.Attributes.y2 "100"
                        , Svg.Attributes.stroke "black"
                        , Svg.Attributes.strokeWidth "1"
                        ]
                        []
                    , Svg.polyline
                        [ Svg.Attributes.points (generateWavePoints 400 model.intensity.value model.frequency.value model.waveType)
                        , Svg.Attributes.fill "none"
                        , Svg.Attributes.stroke "purple"
                        , Svg.Attributes.strokeWidth "5"
                        ]
                        []
                    ]
                ]
            , div [ class "lfoparams" ]
                [ div [ class "paramrow" ]
                    [ div [ class "labeledknob" ] [ Html.map FrequencyMsg (Knob.view 30 model.frequency), text "Freq" ]
                    , div [ class "labeledknob" ] [ Html.map IntensityMsg (Knob.view 30 model.intensity), text "Intensity" ]
                    ]
                , div [ class "paramrow" ]
                    [ select [ class "wave-type-select", onInput WaveTypeChanged ]
                        [ option [ value "sine" ] [ text "Sine" ]
                        , option [ value "square" ] [ text "Square" ]
                        , option [ value "sawtooth" ] [ text "Sawtooth" ]
                        ]
                    ]
                ]
            ]
        ]



-- UPDATE


type Msg
    = FrequencyMsg Knob.Msg
    | IntensityMsg Knob.Msg
    | WaveTypeChanged String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FrequencyMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.frequency
            in
            ( { model | frequency = newKnob }
            , maybeValue
                |> Maybe.map (\value -> SoundEngineController.stepEngine (SoundEngineController.encode_lfo_frequency value))
                |> Maybe.withDefault Cmd.none
            )

        IntensityMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.intensity
            in
            ( { model | intensity = newKnob }
            , maybeValue
                |> Maybe.map (\value -> SoundEngineController.stepEngine (SoundEngineController.encode_lfo_intensity value))
                |> Maybe.withDefault Cmd.none
            )

        WaveTypeChanged waveTypeString ->
            let
                newWaveType =
                    case waveTypeString of
                        "square" ->
                            Square

                        "sawtooth" ->
                            Sawtooth

                        "triangle" ->
                            Triangle

                        _ ->
                            Sine
            in
            ( { model | waveType = newWaveType }
            , SoundEngineController.stepEngine (SoundEngineController.encode_lfo_wave_type waveTypeString)
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map FrequencyMsg
            (Knob.subscriptions model.frequency)
        , Sub.map
            IntensityMsg
            (Knob.subscriptions model.intensity)
        ]

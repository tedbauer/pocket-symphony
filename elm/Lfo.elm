port module Lfo exposing (..)

import Html exposing (Html, div, li, text, ul)
import Html.Attributes exposing (class, height, width)
import Html.Events exposing (onMouseDown)
import Knob
import Svg exposing (line, svg)
import Svg.Attributes


type alias Model =
    { frequency : Knob.Model
    , intensity : Knob.Model
    }



-- MODEL


init : Model
init =
    { frequency = Knob.init 1 0 50 0.1
    , intensity = Knob.init 1 0 200 0.1
    }



-- VIEW


generateWavePoints : Int -> Float -> Float -> String
generateWavePoints width amplitude frequency =
    List.range 0 width
        |> List.map
            (\x ->
                let
                    y =
                        amplitude * sin (frequency * toFloat x * pi / 180)
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
                        [ Svg.Attributes.points (generateWavePoints 400 model.intensity.value model.frequency.value)
                        , Svg.Attributes.fill "none"
                        , Svg.Attributes.stroke "purple"
                        , Svg.Attributes.strokeWidth "5"
                        ]
                        []
                    ]
                ]
            , div [ class "lfoparams" ]
                [ div [ class "labeledknob" ] [ Html.map FrequencyMsg (Knob.view 30 model.frequency), text "Freq" ]
                , div [ class "labeledknob" ] [ Html.map IntensityMsg (Knob.view 30 model.intensity), text "Intensity" ]
                ]
            ]
        ]



-- UPDATE


type Msg
    = FrequencyMsg Knob.Msg
    | IntensityMsg Knob.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FrequencyMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.frequency
            in
            ( { model | frequency = newKnob }, maybeValue |> Maybe.map transmitLfoFrequency |> Maybe.withDefault Cmd.none )

        IntensityMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.intensity
            in
            ( { model | intensity = newKnob }, maybeValue |> Maybe.map transmitLfoIntensity |> Maybe.withDefault Cmd.none )



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



-- PORTS


port transmitLfoFrequency : Float -> Cmd msg


port transmitLfoIntensity : Float -> Cmd msg

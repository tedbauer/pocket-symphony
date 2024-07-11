port module Lfo exposing (..)

import Html exposing (Html, div, li, text, ul)
import Html.Attributes exposing (class, height, width)
import Html.Events exposing (onMouseDown)
import Svg exposing (line, svg)
import Svg.Attributes


type alias Model =
    { frequency : Float
    , intensity : Float
    }



-- MODEL


init : Model
init =
    { frequency = 10
    , intensity = 9
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
                        [ Svg.Attributes.points (generateWavePoints 400 model.intensity model.frequency)
                        , Svg.Attributes.fill "none"
                        , Svg.Attributes.stroke "purple"
                        , Svg.Attributes.strokeWidth "5"
                        ]
                        []
                    ]
                ]
            , div [ class "lfoparams" ]
                [ ul [] [ li [] [ div [ class "parambutton", onMouseDown (SetFrequency (model.frequency + 1)) ] [ text "➕" ], div [ class "parambutton", onMouseDown (SetFrequency (model.frequency - 1)) ] [ text "➖" ], text "Frequency: ", text (String.fromFloat model.frequency) ], li [] [ div [ class "parambutton", onMouseDown (SetIntensity (model.intensity + 1)) ] [ text "➕" ], div [ class "parambutton", onMouseDown (SetIntensity (model.intensity - 1)) ] [ text "➖" ], text "Intensity: ", text (String.fromFloat model.intensity) ], li [] [ text "Wave" ], li [] [ text "Target" ] ] ]
            ]
        ]



-- UPDATE


type Msg
    = SetFrequency Float
    | SetIntensity Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetFrequency frequency ->
            ( { model | frequency = frequency }, transmitLfoFrequency (round frequency) )

        SetIntensity intensity ->
            ( { model | intensity = intensity }, transmitLfoIntensity (round intensity) )



-- PORTS


port transmitLfoFrequency : Int -> Cmd msg


port transmitLfoIntensity : Int -> Cmd msg

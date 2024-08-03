module Knob exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (on)
import Json.Decode as Decode


type alias Model =
    { value : Float
    , min : Float
    , max : Float
    , step : Float
    , dragging : Bool
    , lastY : Maybe Float
    }


type Msg
    = StartDrag
    | Drag Float
    | StopDrag


init : Float -> Float -> Float -> Float -> Model
init initialValue min max step =
    { value = initialValue
    , min = min
    , max = max
    , step = step
    , dragging = False
    , lastY = Nothing
    }


update : Msg -> Model -> ( Model, Maybe Float )
update msg model =
    case msg of
        StartDrag ->
            ( { model | dragging = True }, Nothing )

        Drag y ->
            let
                delta =
                    case model.lastY of
                        Just lastY ->
                            (lastY - y) / 100

                        Nothing ->
                            0

                newValue =
                    clamp model.min model.max (model.value + delta * (model.max - model.min))

                steppedValue =
                    toFloat (round (newValue / model.step)) * model.step
            in
            ( { model | value = steppedValue, lastY = Just y }, Just steppedValue )

        StopDrag ->
            ( { model | dragging = False, lastY = Nothing }, Nothing )


view : Model -> Html Msg
view model =
    let
        rotation =
            (model.value - model.min) / (model.max - model.min) * 270 - 135
    in
    div
        [ class "knob"
        , style "border-radius" "50%"
        , style "position" "relative"
        , style "cursor" "pointer"
        , on "mousedown" (Decode.succeed StartDrag)
        ]
        [ div
            [ class "knob-pointer"
            , style "transform" ("translateX(-50%) rotate(" ++ String.fromFloat rotation ++ "deg)")
            , style "transform-origin" "bottom"
            ]
            []
        , div
            [ style "position" "absolute"
            , style "bottom" "-20px"
            , style "left" "0"
            , style "width" "100%"
            , style "text-align" "center"
            ]
            [ text (String.fromFloat (toFloat (round (model.value * 100)) / 100)) ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.dragging then
        Sub.batch
            [ Browser.Events.onMouseMove (Decode.map Drag (Decode.field "clientY" Decode.float))
            , Browser.Events.onMouseUp (Decode.succeed StopDrag)
            ]

    else
        Sub.none

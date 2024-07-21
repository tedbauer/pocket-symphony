module Knob exposing (Model, Msg, init, update, view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (on)
import Json.Decode as Decode

type alias Model =
    { value : Float
    , min : Float
    , max : Float
    , step : Float
    , label : String
    }

type Msg
    = SetValue Float

init : String -> Float -> Float -> Float -> Float -> Model
init label min max step initialValue =
    { value = initialValue
    , min = min
    , max = max
    , step = step
    , label = label
    }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetValue newValue ->
            let
                clampedValue =
                    clamp model.min model.max newValue
            in
            ( { model | value = clampedValue }, Cmd.none )

view : Model -> Html Msg
view model =
    div [ class "knob-container" ]
        [ div
            [ class "knob"
            , style "transform" ("rotate(" ++ String.fromFloat (valueToRotation model) ++ "deg)")
            , on "mousedown" (Decode.map SetValue (decodeKnobEvent model))
            ]
            []
        , div [ class "knob-label" ] [ text (model.label ++ ": " ++ String.fromFloat (roundToStep model.value model.step)) ]
        ]

valueToRotation : Model -> Float
valueToRotation model =
    (model.value - model.min) / (model.max - model.min) * 270 - 135

decodeKnobEvent : Model -> Decode.Decoder Float
decodeKnobEvent model =
    Decode.map2 (\pageX pageY -> calculateValue model pageX pageY)
        (Decode.field "pageX" Decode.float)
        (Decode.field "pageY" Decode.float)

calculateValue : Model -> Float -> Float -> Float
calculateValue model pageX pageY =
    let
        knobRect =
            { left = 0, top = 0, width = 60, height = 60 }

        centerX =
            knobRect.left + (knobRect.width / 2)

        centerY =
            knobRect.top + (knobRect.height / 2)

        angle =
            atan2 (pageY - centerY) (pageX - centerX)

        normalizedAngle =
            if angle < 0 then
                angle + 2 * pi
            else
                angle

        proportion =
            (normalizedAngle + pi / 2) / (2 * pi)

        range =
            model.max - model.min
    in
    model.min + (range * proportion)

roundToStep : Float -> Float -> Float
roundToStep value step =
    toFloat (round (value / step)) * step

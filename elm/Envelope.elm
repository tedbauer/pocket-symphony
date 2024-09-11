port module Envelope exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, height, style, width)
import Knob
import SoundEngineController
import Svg exposing (path, svg)
import Svg.Attributes


type alias Model =
    { attack : Knob.Model
    , sustain : Knob.Model
    , decay : Knob.Model
    , release : Knob.Model
    }



-- MODEL


init : Model
init =
    { attack = Knob.init 0 0 0.19 0.01
    , sustain = Knob.init 0.5 0.1 0.55 0.01
    , decay = Knob.init 0.1 0 0.15 0.01
    , release = Knob.init 0.05 0 0.1 0.01
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "card" ]
        [ div [ class "cardtitle" ] [ text "✉️ Envelope" ]
        , div [ class "envelope" ]
            [ graph model.attack.value model.decay.value model.sustain.value model.release.value
            , div [ class "envelopecontrol" ]
                [ div [ class "envelopeknob" ]
                    [ Html.map AttackMsg (Knob.view 30 model.attack)
                    , text "Attack"
                    ]
                , div [ class "labeledknob" ] [ Html.map DecayMsg (Knob.view 30 model.decay), text "Decay" ]
                , div [ class "labeledknob" ] [ Html.map SustainMsg (Knob.view 30 model.sustain), text "Sustain" ]
                , div [ class "labeledknob" ] [ Html.map ReleaseMsg (Knob.view 30 model.release), text "Release" ]
                ]
            ]
        ]


graph : Float -> Float -> Float -> Float -> Html Msg
graph attack decay sustain release =
    let
        points =
            generateWavePoints attack decay sustain release

        pointsList =
            String.split " " points

        xOffset =
            20

        yOffset =
            40

        -- Increased vertical offset
    in
    div [ class "graph" ]
        [ svg
            [ width 200
            , height 100
            , Svg.Attributes.viewBox ("0 0 " ++ String.fromInt (500 + xOffset) ++ " " ++ String.fromInt (200 + yOffset))
            ]
            [ Svg.g [ Svg.Attributes.transform ("translate(" ++ String.fromInt xOffset ++ ", " ++ String.fromInt yOffset ++ ")") ]
                [ Svg.polyline
                    [ Svg.Attributes.points points
                    , Svg.Attributes.fill "none"
                    , Svg.Attributes.stroke "purple"
                    , Svg.Attributes.strokeWidth "2"
                    ]
                    []
                , Svg.g [] (List.map drawPoint pointsList)

                -- X-axis line
                , Svg.line
                    [ Svg.Attributes.x1 "0"
                    , Svg.Attributes.y1 "180"
                    , Svg.Attributes.x2 "500"
                    , Svg.Attributes.y2 "180"
                    , Svg.Attributes.stroke "black"
                    , Svg.Attributes.strokeWidth "1"
                    ]
                    []
                ]

            -- Y-axis line (moved to the left edge of the graph)
            , Svg.line
                [ Svg.Attributes.x1 (String.fromInt xOffset)
                , Svg.Attributes.y1 (String.fromInt yOffset)
                , Svg.Attributes.x2 (String.fromInt xOffset)
                , Svg.Attributes.y2 (String.fromInt (180 + yOffset))
                , Svg.Attributes.stroke "black"
                , Svg.Attributes.strokeWidth "1"
                ]
                []
            ]
        ]


drawPoint : String -> Svg.Svg Msg
drawPoint point =
    let
        coordinates =
            String.split "," point

        x =
            Maybe.withDefault "0" (List.head coordinates)

        y =
            Maybe.withDefault "0" (List.head (List.drop 1 coordinates))
    in
    Svg.circle
        [ Svg.Attributes.cx x
        , Svg.Attributes.cy y
        , Svg.Attributes.r "5"
        , Svg.Attributes.fill "purple"
        ]
        []


generateWavePoints : Float -> Float -> Float -> Float -> String
generateWavePoints attack decay sustain release =
    let
        width =
            500

        height =
            180

        attackEnd =
            attack * width

        decayEnd =
            attackEnd + decay * width

        sustainEnd =
            decayEnd + sustain * width

        releaseEnd =
            sustainEnd + release * width

        sustainLevel =
            height - (sustain * height)
    in
    String.join " "
        [ "0," ++ String.fromFloat height
        , String.fromFloat attackEnd ++ ",0"
        , String.fromFloat decayEnd ++ "," ++ String.fromFloat sustainLevel
        , String.fromFloat sustainEnd ++ "," ++ String.fromFloat sustainLevel
        , String.fromFloat releaseEnd ++ "," ++ String.fromFloat height
        ]



-- UPDATE


type Msg
    = AttackMsg Knob.Msg
    | SustainMsg Knob.Msg
    | DecayMsg Knob.Msg
    | ReleaseMsg Knob.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AttackMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.attack
            in
            ( { model | attack = newKnob }
            , maybeValue |> Maybe.map (SoundEngineController.encode_envelope "attack") |> Maybe.map SoundEngineController.stepEngine |> Maybe.withDefault Cmd.none
            )

        SustainMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.sustain
            in
            ( { model | sustain = newKnob }
            , maybeValue |> Maybe.map (SoundEngineController.encode_envelope "sustain") |> Maybe.map SoundEngineController.stepEngine |> Maybe.withDefault Cmd.none
            )

        DecayMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.decay
            in
            ( { model | decay = newKnob }
            , maybeValue |> Maybe.map (SoundEngineController.encode_envelope "decay") |> Maybe.map SoundEngineController.stepEngine |> Maybe.withDefault Cmd.none
            )

        ReleaseMsg knobMsg ->
            let
                ( newKnob, maybeValue ) =
                    Knob.update knobMsg model.release
            in
            ( { model | release = newKnob }
            , maybeValue |> Maybe.map (SoundEngineController.encode_envelope "release") |> Maybe.map SoundEngineController.stepEngine |> Maybe.withDefault Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map AttackMsg
            (Knob.subscriptions model.attack)
        , Sub.map
            SustainMsg
            (Knob.subscriptions model.sustain)
        , Sub.map DecayMsg (Knob.subscriptions model.decay)
        , Sub.map ReleaseMsg (Knob.subscriptions model.release)
        ]



-- PORTS


port transmitAttack : Float -> Cmd msg


port transmitSustain : Float -> Cmd msg


port transmitDecay : Float -> Cmd msg


port transmitRelease : Float -> Cmd msg

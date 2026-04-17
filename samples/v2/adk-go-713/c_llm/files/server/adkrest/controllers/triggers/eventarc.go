// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package triggers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"google.golang.org/adk/agent"
	"google.golang.org/adk/artifact"
	"google.golang.org/adk/memory"
	"google.golang.org/adk/runner"
	"google.golang.org/adk/server/adkrest/internal/models"
	"google.golang.org/adk/session"
)

const (
	eventarcDefaultUserID       = "eventarc-caller"
	cloudEventsContentType      = "application/cloudevents+json"
	pubsubMessagePublishedType  = "google.cloud.pubsub.topic.v1.messagePublished"
)

// EventarcController handles the Eventarc trigger endpoints.
type EventarcController struct {
	runner    *RetriableRunner
	semaphore chan struct{}
}

// NewEventarcController creates a new EventarcController.
func NewEventarcController(sessionService session.Service, agentLoader agent.Loader, memoryService memory.Service, artifactService artifact.Service, pluginConfig runner.PluginConfig, triggerConfig TriggerConfig) *EventarcController {
	return &EventarcController{
		runner: &RetriableRunner{
			sessionService:  sessionService,
			agentLoader:     agentLoader,
			memoryService:   memoryService,
			artifactService: artifactService,
			pluginConfig:    pluginConfig,
			triggerConfig:   triggerConfig,
		},
		semaphore: make(chan struct{}, triggerConfig.MaxConcurrentRuns),
	}
}

// EventarcTriggerHandler handles the Eventarc trigger endpoint.
func (c *EventarcController) EventarcTriggerHandler(w http.ResponseWriter, r *http.Request) {
	event, errMsg, errStatus := parseEventarcRequest(r)
	if errMsg != "" {
		http.Error(w, errMsg, errStatus)
		return
	}

	messageContent, errStatus, err := messageContentFromEventarc(event)
	if err != nil {
		respondError(w, errStatus, err.Error())
		return
	}

	appName, err := appName(r)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	userID := event.Source
	if userID == "" {
		userID = eventarcDefaultUserID
	}

	if c.semaphore != nil {
		c.semaphore <- struct{}{}
		defer func() { <-c.semaphore }()
	}

	if _, err := c.runner.RunAgent(r.Context(), appName, userID, messageContent); err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("failed to run agent: %v", err))
		return
	}

	respondSuccess(w)
}

func parseEventarcRequest(r *http.Request) (models.EventarcTriggerRequest, string, int) {
	var event models.EventarcTriggerRequest
	if r.Header.Get("Content-Type") == cloudEventsContentType {
		if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
			return event, "Bad Request", http.StatusBadRequest
		}
	} else {
		event.ID = r.Header.Get("ce-id")
		event.Type = r.Header.Get("ce-type")
		event.Source = r.Header.Get("ce-source")
		event.SpecVersion = r.Header.Get("ce-specversion")
		event.Time = r.Header.Get("ce-time")

		bodyBytes, err := io.ReadAll(r.Body)
		if err != nil {
			return event, "Failed to read body", http.StatusInternalServerError
		}
		event.Data = bodyBytes
	}
	return event, "", 0
}

func messageContentFromEventarc(event models.EventarcTriggerRequest) (string, int, error) {
	if event.Type == pubsubMessagePublishedType {
		var pubsub models.PubSubTriggerRequest
		if err := json.Unmarshal(event.Data, &pubsub); err != nil {
			return "", http.StatusInternalServerError, fmt.Errorf("failed to unmarshal pubsub data: %v", err)
		}
		content, err := messageContentFromPubSub(pubsub)
		if err != nil {
			return "", http.StatusBadRequest, err
		}
		return content, 0, nil
	}

	messageBytes, err := json.Marshal(event)
	if err != nil {
		return "", http.StatusInternalServerError, fmt.Errorf("failed to marshal agent message: %v", err)
	}
	return string(messageBytes), 0, nil
}

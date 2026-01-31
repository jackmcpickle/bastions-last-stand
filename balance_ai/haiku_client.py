"""Claude Haiku API client for balance analysis."""

import json
import os
import time
from typing import Any, Dict

from anthropic import Anthropic
from dotenv import load_dotenv

from prompts import build_analysis_prompt

load_dotenv()


class HaikuClient:
    def __init__(self):
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            raise ValueError("ANTHROPIC_API_KEY not set in environment or .env file")

        self.client = Anthropic(api_key=api_key)
        self.model = "claude-haiku-4-5-20251001"
        self.request_delay = 1.0  # Delay between requests to avoid rate limits
        self.last_request_time = 0

    def analyze(
        self,
        config: Dict[str, Any],
        results: Dict[str, Any],
        targets: Dict[str, Any],
        goal: str,
    ) -> Dict[str, Any]:
        """Send results to Haiku, get recommendations."""

        # Rate limit delay
        elapsed = time.time() - self.last_request_time
        if elapsed < self.request_delay:
            time.sleep(self.request_delay - elapsed)

        parameter_bounds = results.get("parameter_bounds", {})
        prompt = build_analysis_prompt(config, results, targets, goal, parameter_bounds)

        response = self.client.messages.create(
            model=self.model,
            max_tokens=2048,
            messages=[{"role": "user", "content": prompt}],
        )

        self.last_request_time = time.time()

        # Parse JSON response
        content = response.content[0].text

        # Extract JSON from response (handle markdown code blocks)
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0]
        elif "```" in content:
            content = content.split("```")[1].split("```")[0]

        try:
            return json.loads(content.strip())
        except json.JSONDecodeError as e:
            # Return error info if JSON parsing fails
            return {
                "error": f"Failed to parse JSON: {e}",
                "raw_response": content,
                "analysis": "Failed to parse AI response",
                "changes": {},
                "converged": False,
                "confidence": 0,
            }

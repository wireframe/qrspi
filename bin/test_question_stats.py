import json
import os
import subprocess
import sys
import tempfile
import unittest

BIN = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(BIN, "question-stats")
QUESTION_TEMPLATE = os.path.join(BIN, os.pardir, "commands", "question.md")

DECISIONS_MD = """# Decisions

## D1: First
**Firmness:** Preference

## D2: Second
**Firmness:** Open

## Deferred
- one
- two
- three
"""


def user_command():
    return {"type": "user", "message": {"content": [
        {"type": "text", "text": "<command-name>/qrspi:question</command-name>"}]}}


def assistant(*items):
    return {"type": "assistant", "message": {"content": list(items)}}


def tool_use(name, arguments):
    return assistant({"type": "tool_use", "name": name, "input": arguments})


def ask_user_question(count):
    return tool_use("AskUserQuestion", {"questions": [{"question": f"Q{i}?"} for i in range(count)]})


def markdown_round():
    return assistant({"type": "text", "text": "❓ **Q1** - **first?**\n\n---\n\n❓ **Q2** - **second?**"})


def write_decisions(content=DECISIONS_MD):
    return tool_use("Write", {"file_path": "x/decisions.md", "content": content})


def bash_writes_decisions():
    command = "mkdir -p d && cat > d/decisions.md <<'EOF'\n" + DECISIONS_MD + "EOF"
    return tool_use("Bash", {"command": command})


class QuestionStatsTest(unittest.TestCase):
    def run_cli(self, records):
        with tempfile.TemporaryDirectory() as directory:
            path = os.path.join(directory, "session.jsonl")
            with open(path, "w") as handle:
                handle.write("\n".join(json.dumps(r) for r in records) + "\n")
            return subprocess.run([sys.executable, TOOL, path],
                                  capture_output=True, text=True)

    def run_tool(self, records):
        result = self.run_cli(records)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_counts_questions_decisions_deferred_and_firmness(self):
        stats = self.run_tool([user_command(), ask_user_question(2),
                               markdown_round(), write_decisions()])
        self.assertEqual(stats, {
            "picker_questions": 2, "markdown_questions": 2,
            "decisions": 2, "deferred": 3,
            "firmness": {"Firm": 0, "Preference": 1, "Open": 1}})

    def test_without_decisions_write_reports_zero_decisions(self):
        stats = self.run_tool([user_command(), ask_user_question(2), markdown_round()])
        self.assertEqual(stats["decisions"], 0)
        self.assertEqual(stats["deferred"], 0)
        self.assertEqual(stats["firmness"], {"Firm": 0, "Preference": 0, "Open": 0})

    def test_questions_after_decisions_write_are_not_counted(self):
        stats = self.run_tool([user_command(), write_decisions(),
                               ask_user_question(3), markdown_round()])
        self.assertEqual(stats["picker_questions"], 0)
        self.assertEqual(stats["markdown_questions"], 0)

    def test_transcript_without_question_start_fails_loudly(self):
        result = self.run_cli([ask_user_question(2), write_decisions()])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no /qrspi:question start found", result.stderr)

    def test_assistant_text_quoting_the_command_tag_is_not_a_start(self):
        quoted = assistant({"type": "text", "text": "<command-name>/qrspi:question</command-name>"})
        result = self.run_cli([quoted, ask_user_question(2), write_decisions()])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no /qrspi:question start found", result.stderr)

    def test_skill_tool_call_counts_as_a_start(self):
        skill = tool_use("Skill", {"skill": "qrspi:question"})
        stats = self.run_tool([skill, ask_user_question(2), write_decisions()])
        self.assertEqual(stats["picker_questions"], 2)

    def test_other_skill_mentioning_question_is_not_a_start(self):
        research = tool_use("Skill", {"skill": "qrspi:research", "args": "after qrspi:question"})
        stats = self.run_tool([user_command(), ask_user_question(2), research, write_decisions()])
        self.assertEqual(stats["picker_questions"], 2)

    def test_files_merely_ending_in_decisions_md_are_not_the_write(self):
        stats = self.run_tool([user_command(),
                               tool_use("Write", {"file_path": "x/old-decisions.md", "content": "## D1: X\n"}),
                               tool_use("Bash", {"command": "cp a > decisions.md.bak"}),
                               write_decisions()])
        self.assertEqual(stats["decisions"], 2)

    def test_indented_markdown_questions_are_counted(self):
        stats = self.run_tool([user_command(), assistant({"type": "text", "text": "  ❓ **Q1** - **first?**"})])
        self.assertEqual(stats["markdown_questions"], 1)

    def test_bash_heredoc_write_of_decisions_counts_as_the_write(self):
        stats = self.run_tool([user_command(), ask_user_question(2), bash_writes_decisions()])
        self.assertEqual(stats["decisions"], 2)
        self.assertEqual(stats["deferred"], 3)

    def test_bash_tee_write_of_decisions_counts_as_the_write(self):
        command = "tee d/decisions.md <<'EOF'\n" + DECISIONS_MD + "EOF"
        stats = self.run_tool([user_command(), ask_user_question(2), tool_use("Bash", {"command": command})])
        self.assertEqual(stats["decisions"], 2)

    def test_missing_transcript_argument_prints_usage(self):
        result = subprocess.run([sys.executable, TOOL], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("usage: question-stats <transcript.jsonl>", result.stderr)

    def test_firmness_ignores_words_that_merely_start_with_a_level(self):
        write = write_decisions("## D1: X\n**Firmness:** Opening\n")
        stats = self.run_tool([user_command(), write])
        self.assertEqual(stats["firmness"]["Open"], 0)

    def test_counts_the_question_format_the_template_prescribes(self):
        with open(QUESTION_TEMPLATE) as handle:
            template_rounds = [line.rstrip("\n") for line in handle if line.lstrip().startswith("❓")]
        round_text = assistant({"type": "text", "text": "\n".join(template_rounds)})
        stats = self.run_tool([user_command(), round_text])
        self.assertEqual(stats["markdown_questions"], len(template_rounds))
        self.assertGreater(len(template_rounds), 0)


if __name__ == "__main__":
    unittest.main()

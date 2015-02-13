# Contributing

We'd love for you to contribute to our source code and to make it even better than it is
today!

Here are the guidelines we'd like you to follow:

 - [Issues](#issues)
 - [Pull Requests](#pulls)
 - [Coding Rules](#rules)
 - [Commit Message Guidelines](#commit)

## <a name="issues"></a> Issues

If you have questions about how to use this component, please open a [GitHub Issue](https://github.com/ef-ctx/CTXPropertyMapper/issues).

If you find a bug in the source code or a mistake in the documentation, you can help us by
submitting an issue to our [GitHub Issue](https://github.com/ef-ctx/CTXPropertyMapper/issues). Even better you can submit a Pull Request
with a fix.

Before you submit your issue search the archive, maybe your question was already answered.

If your issue appears to be a bug, and hasn't been reported, open a new issue.
Help us to maximize the effort we can spend fixing issues and adding new
features, by not reporting duplicate issues.  Providing the following information will increase the
chances of your issue being dealt with quickly:

* **Overview of the Issue** - if an error is being thrown a formatted stack trace will be very helpful
* **Motivation for or Use Case** - explain why this is a bug for you
* **Version(s) Affected** - is it a regression?
* **Systems Affected** - identify platform/os/browser where applicable
* **Reproduce the Error** - if possible, provide a set of steps
* **Related Issues** - has a similar issue been reported before? please link it
* **Suggest a Fix** - if you can't fix the bug yourself, perhaps you can point to what might be
  causing the problem (line of code or commit)

## <a name="pulls"></a> Pull Requests

Before you submit your pull request consider the following guidelines:

* Search [Pull Requests](https://github.com/ef-ctx/CTXPropertyMapper/pulls) for an open or closed Pull Request
  that relates to your submission. You don't want to duplicate effort.
* Make your changes in a new git branch:

     ```shell
     git checkout -b fix-branch master
     ```

* Create your patch, **including appropriate test cases**.
* Limit the changes to a well defined scope.
* Avoid performing unrelated changes, even if minor (like fixing typos or code style in unrelated files).
* Run the full test suites and ensure that all tests pass.
* Follow the existing code style and guidelines where available.
* Make sure you run existing beautifiers if available.
* Commit your changes using a descriptive commit message that follows our [commit message conventions](#commit).

     ```shell
     git commit -a
     ```
  Note: the optional commit `-a` command line option will automatically "add" and "rm" edited files.

* Build your changes locally to ensure all the tests pass:

* Push your branch to GitHub:

    ```shell
    git push origin fix-branch
    ```

* In GitHub, send a pull request to `CTXPropertyMapper:master`.
* If we suggest changes then:
  * Make the required updates.
  * Re-run the test suite to ensure tests are still passing.
  * Rebase your branch and force push to your GitHub repository (this will update your Pull Request):

    ```shell
    git rebase master -i
    git push origin fix-branch -f
    ```

That's it! Thank you for your contribution!

### After your pull request is merged

After your pull request is merged, you can safely delete your branch and pull the changes
from the main (upstream) repository:

* Delete the remote branch on GitHub either through the GitHub web UI or your local shell as follows:

    ```shell
    git push origin --delete fix-branch
    ```

* Check out the master branch:

    ```shell
    git checkout master -f
    ```

* Delete the local branch:

    ```shell
    git branch -D fix-branch
    ```

* Update your master with the latest upstream version:

    ```shell
    git pull --ff upstream master
    ```

## <a name="rules"></a> Coding Rules

To ensure consistency throughout the source code, keep these rules in mind as you are working:

* All features or bug fixes **must be tested** by one or more unit tests.
* All public API methods **must be documented** in consistency with existing documentation.

## <a name="commit"></a> Git Commit Guidelines

We have very precise rules over how our git commit messages can be formatted.  This leads to **more
readable messages** that are easy to follow when looking through the **project history**.  But also,
we use the git commit messages to **generate the CHANGELOG**.

### Commit Message Format

Each commit message consists of a **header** and a **body**.  The header has a special format that includes
a **type**, a **scope** and a **subject**:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
```

Any line of the commit message cannot be longer 100 characters! This allows the message to be easier
to read on github as well as in various git tools.

### Type
Must be one of the following:

* **feat**: A new feature
* **fix**: A bug fix
* **docs**: Documentation only changes
* **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing
  semi-colons, etc)
* **refactor**: A code change that neither fixes a bug or adds a feature
* **perf**: A code change that improves performance
* **test**: Adding missing tests
* **chore**: Changes to the build process or auxiliary tools and libraries such as documentation
  generation

### Scope
The scope could be anything specifying place of the commit change. For example `config`,
`controller`, `filter`, etc...

### Subject
The subject contains succinct description of the change:

* use the imperative, present tense: "change" not "changed" nor "changes"
* don't capitalize
* no dot (.) at the end

### Body
Provide more details about the commit in the message body, after the blank link:

- include the motivation for the change and contrast this with previous behavior.
- include information about **Breaking Changes**
- reference existing Github issue(s) number via `GH-xxxx` instead of `#xxx`.

Just as in the **subject**, use the imperative, present tense: "change" not "changed" nor "changes".

---
Adapted from https://github.com/angular/angular.js/blob/master/CONTRIBUTING.md
# Project Name

This is a template repository based off [Creating a template repository](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-template-repository) and [Creating a repository from a template](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-from-a-template). Remember to review the GitHub repository guidelines in Confluence before creating a new repository and also remove this message after cloning this template into your new project repository.

Project description - one or two paragraphs. Microservices are fun and complex. This service addresses all of our authentication needs!

- [Getting Started](#getting-started)
- [How it Works](#how-it-works)
- [Developing](#developing)
  - [Prerequisites](#prerequisites)
  - [Testing](#testing)
  - [Contributing](#contributing)
- [Digital Engineering](#digital-engineering)
- [Licensing](#licensing)

## Getting Started

{Minimal steps required for a quick software trial.}

```js
import { Myservice } from '@omf/my-service';

const theservice = new Myservice();

export default theservice;
```

## How it works

{Describe how it works. Include images if possible.}

## Developing

{Show how engineers can set up a development environment and contribute.}

### Prerequisites

{Explain the prerequisites}

### Testing

{Notes on testing}

### Contributing

{How can the community contribute}

## Digital Engineering

{List generic details of the team who maintains the repository }

## Licensing

OneMain Internal Only - [full license](./LICENSE)

## .gitconfig

This contains pre-approved patterns that won't be blocked by .gitsecrets during commits, pushes and pull requests.

To sync these changes locally with your machine run:

```bash
git config --local include.path ../.gitconfig
```

## .ignore files

Remove any ignore files you don't need for your project and rename the one you do to .gitignore.
After this, remove this section of the readme.

@GrabResolver(name = 'spring-snapshot', root = 'https://repo.spring.io/libs-snapshot-local')
@Grapes([
	// transitive has to be [false], otherwise some strange stackoverflow issues are thrown
	@Grab(group = 'io.cloudpipelines', module = 'project-crawler', version = '1.0.0.BUILD-SNAPSHOT', transitive = false, changing = true),
	@Grab(group = 'ch.qos.logback', module = 'logback-classic', version='1.2.3'),
	@Grab(group = 'commons-logging', module = 'commons-logging', version = '1.2'),
	@Grab(group = 'com.fasterxml.jackson.core', module = 'jackson-core', version = '2.9.9'),
	@Grab(group = 'com.fasterxml.jackson.core', module = 'jackson-databind', version = '2.9.9.1'),
	@Grab(group = 'com.fasterxml.jackson.dataformat', module = 'jackson-dataformat-yaml', version = '2.9.9'),
	@Grab(group = 'com.jcabi', module = 'jcabi-github', version = '1.0'),
	@Grab(group = 'org.glassfish', module = 'javax.json', version = '1.1.4'),
	@Grab(group = 'org.gitlab', module = 'java-gitlab-api', version = '4.0.0'),
	@Grab(group = 'com.squareup.okhttp3', module = 'okhttp', version = '4.0.1')
])
import com.fasterxml.jackson.databind.DeserializationFeature
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import groovy.transform.CompileStatic
import groovy.transform.Field
import io.cloudpipelines.projectcrawler.OptionsBuilder
import io.cloudpipelines.projectcrawler.Repository
import io.cloudpipelines.projectcrawler.ProjectCrawler

/*
	// tag::description[]
	The arguments for this script will be taken in the order:
	Arguments, System Properties, Environment Variables

	Arguments:
	0 - rootUrl - root URL of the SCM server's API
	1 - username - username to connect to the API
	2 - password - password to connect to the API
	3 - token - token to connect to the API
	4 - repoProjectsExcludePattern - pattern to exclude certain projects
	5 - repoType - type of SCM repo server (GITHUB, GITLAB, BITBUCKET, OTHER)
	6 - org - organization / project name
	7 - pipelineDescriptor - name of the pipeline descriptor
	8 - alias - alias to be used by FLY CLI to set the pipeline
	9 - credentials - credentials file to be used by FLY CLI to set the pipeline

	System props with the name equal to arguments (e.g. rootUrl)
	Environment variables are upper case arguments with CRAWLER_ prefix (e.g. CRAWLER_ROOTURL)

	E.g. of calling the script

	#!/bin/bash

	set -o errexit
	set -o errtrace
	set -o pipefail

	export CRAWLER_ROOTURL="https://github.com"
	export CRAWLER_USERNAME="username"
	export CRAWLER_PASSWORD="password"
	export CRAWLER_TOKEN=""
	export CRAWLER_REPOPROJECTSEXCLUDEPATTERN=""
	export CRAWLER_REPOTYPE=""
	export CRAWLER_ORG="my-org"
	export CRAWLER_PIPELINEDESCRIPTOR="my-pipelines.yml"
	export CRAWLER_ALIAS="alias"
	export CRAWLER_CREDENTIALS="credentials-cf.yml"

	./set_pipeline_crawler.sh

	// end::description[]
 */

String fromList(int index) { args.length >= index + 1 ? args[index] : "" }
@Field Map<String, String> arguments = [
	rootUrl                   : fromList(0),
	username                  : fromList(1),
	password                  : fromList(2),
	token                     : fromList(3),
	repoProjectsExcludePattern: fromList(4),
	repoType                  : fromList(5),
	org                       : fromList(6),
	pipelineDescriptor        : fromList(7),
	alias                     : fromList(8),
	credentials               : fromList(9),
]

String propOrEnv(String prop) {
	return arguments[prop] ?:
		System.getProperty(prop) ?:
			System.getenv("CRAWLER_" + prop.toUpperCase()) ?: ""
}

void updatePropsAndRun(Repository repository) {
	println "Updating the pipeline [${repository.name}]"
	File build = new File("build")
	build.mkdirs()
	File newCreds = new File(build, repository.name
		.replaceAll("[^a-zA-Z0-9\\.\\-]", "_") + ".yml")
	newCreds.text =
		new File(propOrEnv("credentials")).text
			.replaceAll("app-url.*", "app-url: " + repository.clone_url)
			.replaceAll("app-branch.*", "app-branch: " + repository.requestedBranch ?: "master")
	def sout = new StringBuilder(), serr = new StringBuilder()
	def proc = "fly -t ${propOrEnv("alias")} sp -p ${repository.name} -c pipeline.yml -l ${newCreds.absolutePath} -n".execute()
	proc.consumeProcessOutput(sout, serr)
	proc.waitForOrKill(5000)
	println "out> $sout err> $serr"
}

// crawl the org
ProjectCrawler crawler = new ProjectCrawler(OptionsBuilder
	.builder().rootUrl(propOrEnv("rootUrl"))
	.username(propOrEnv("username"))
	.password(propOrEnv("password"))
	.token(propOrEnv("token"))
	.exclude(propOrEnv("repoProjectsExcludePattern"))
	.repository(propOrEnv("repoType")).build())

// get the repos from the org
String org = propOrEnv("org")
List<Repository> repositories = crawler.repositories(org)
println "Found the following repositories ${repositories} in org [${org}]"

Map<String, Exception> errors = [:]
String pipelineDescriptor = propOrEnv("pipelineDescriptor") ?: "cloud-pipelines.yml"
// generate jobs and store errors
repositories.each { Repository repo ->
	try {
		println "Processing repo [${repo.name}]"
		// fetch the descriptor (or pick one for tests form env var)
		String descriptor = crawler.fileContent(org,
			repo.name, repo.requestedBranch, pipelineDescriptor)
		// parse it
		PipelineDescriptor pipeline = PipelineDescriptor.from(descriptor)
		if (pipeline.hasMonoRepoProjects()) {
			// for monorepos treat the single repo as multiple ones
			pipeline.pipeline.project_names.each { String monoRepo ->
				Repository monoRepository = new Repository(monoRepo, repo.ssh_url, repo.clone_url, repo.requestedBranch)
				println "Processing mono repo [${monoRepository.name}]"
				updatePropsAndRun(monoRepository)
			}
		} else {
			// for any other repo build a single pipeline
			updatePropsAndRun(repo)
		}
	} catch (Exception e) {
		errors.put(repo.name, e)
		return
	}
}

if (!errors.isEmpty()) {
	println "\n\n\nWARNING, THERE WERE ERRORS WHILE TRYING TO BUILD PROJECTS\n\n\n"
	errors.each { String key, Exception error ->
		println "Exception for project [${key}], [${error}]"
		println "Stacktrace:"
		error.printStackTrace()
	}
}


/**
 * The model representing {@code cloud-pipelines.yml} descriptor
 *
 * @author Marcin Grzejszczak
 * @since 1.0.0
 */
@CompileStatic
class PipelineDescriptor {
	String language_type
	Build build = new Build()
	Pipeline pipeline = new Pipeline()
	Environment test = new Environment()
	Environment stage = new Environment()
	Environment prod = new Environment()

	boolean hasMonoRepoProjects() {
		return !pipeline.project_names.empty
	}

	@CompileStatic
	static class Build {
		String main_module
	}

	@CompileStatic
	static class Pipeline {
		List<String> project_names = []
		Boolean api_compatibility_step
		Boolean test_step
		Boolean rollback_step
		Boolean stage_step
		Boolean auto_stage
		Boolean auto_prod
	}

	@CompileStatic
	static class Environment {
		List<Service> services = []
		String deployment_strategy = ""
	}

	@CompileStatic
	static class Service {
		String type, name, coordinates, pathToManifest, broker, plan
	}

	static PipelineDescriptor from(String yaml) {
		if (!yaml) {
			return new PipelineDescriptor()
		}
		ObjectMapper objectMapper = new ObjectMapper(new YAMLFactory())
		objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
		return objectMapper.readValue(yaml, PipelineDescriptor)
	}
}

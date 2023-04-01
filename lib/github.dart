import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// See: https://int128.hatenablog.com/entry/2017/09/05/161641

class GitHub {
  static Map<String, String> _createHeaders(final String accessToken) {
    return {
      'Accept': 'application/vnd.github+json',
      'Authorization': 'Bearer $accessToken',
      'X-GitHub-Api-Version': '2022-11-28'
    };
  }

  static Future<String> _getCommitUrlFromBranchHead(
      final Map<String, String> headers,
      final String owner,
      final String repo,
      final String branch) async {
    final response = await http.get(
        Uri.https(
            'api.github.com', '/repos/$owner/$repo/git/refs/heads/$branch'),
        headers: headers);
    final json = await jsonDecode(response.body) as Map<String, dynamic>;
    final object = json['object'] as Map<String, String>;
    return object['url'] ?? '';
  }

  static Future<String> _getCommit(
      final Map<String, String> headers, final String url) async {
    final splitted = url.substring(8).split('/');
    final host = splitted[0];
    final path = splitted.skip(0).join('/');

    final response = await http.get(Uri.https(host, path), headers: headers);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tree = json['tree'] as Map<String, String>;
    return tree['sha'] ?? '';
  }

  static Future<String> _createBlob(final Map<String, String> headers,
      final String owner, final String repo, final String contents) async {
    final response = await http.post(
        Uri.https('api.github.com', '/repos/$owner/$repo/git/blobs'),
        headers: headers,
        body: {'content': contents, 'encoding': 'utf-8'});
    final json = await jsonDecode(response.body) as Map<String, String>;
    return json['sha'] ?? '';
  }

  static Future<String> _createTree(
      final Map<String, String> headers,
      final String owner,
      final String repo,
      final String shaOfParent,
      final String shaOfBlob,
      final String filename) async {
    final response = await http.post(
        Uri.https('api.github.com', '/repos/$owner/$repo/git/trees'),
        headers: headers,
        body: {
          'base_tree': shaOfParent,
          'tree': [
            {
              'path': filename,
              'mode': '100644',
              'type': 'blob',
              'sha': shaOfBlob
            }
          ]
        });
    final json = await jsonDecode(response.body) as Map<String, dynamic>;
    return json['sha'] ?? '';
  }

  static Future<String> _createCommit(
      final Map<String, String> headers,
      final String owner,
      final String repo,
      final String message,
      final String author,
      final String email,
      final String shaOfParent,
      final String shaOfTree) async {
    final response = await http.post(
        Uri.https('api.github.com', '/repos/$owner/$repo/git/trees'),
        headers: headers,
        body: {
          'message': message,
          'author': {
            'name': author,
            'email': email,
            'date': DateTime.now().toIso8601String()
          },
          'parents': [shaOfParent],
          'tree': shaOfTree
        });
    final json = await jsonDecode(response.body) as Map<String, String>;
    return json['sha'] ?? '';
  }

  static Future<Map<String, dynamic>> _updateRef(
      final Map<String, String> headers,
      final String owner,
      final String repo,
      final String branch,
      final String shaOfCommit) async {
    final response = await http.patch(
        Uri.https(
            'api.github.com', '/repos/$owner/$repo/git/refs/heads/$branch'),
        headers: headers,
        body: {'sha': shaOfCommit, 'force': false});
    return await jsonDecode(response.body) as Map<String, String>;
  }

  static Future<void> pushFile(
      final String accessToken,
      final String owner,
      final String repo,
      final String branch,
      final File file,
      final String message,
      final String author,
      final String email) async {
    final filename = file.path.split('/').last;
    debugPrint('### filename: $filename');
    final contents = await file.readAsString();
    debugPrint('### contents: $contents');
    final headers = _createHeaders(accessToken);
    debugPrint('### headers: $headers');
    final url = await _getCommitUrlFromBranchHead(headers, owner, repo, branch);
    debugPrint('### url: $url');
    final shaOfParent = await _getCommit(headers, url);
    debugPrint('### shaOfParent: $shaOfParent');
    final shaOfBlob = await _createBlob(headers, owner, repo, contents);
    debugPrint('### shaOfBlob: $shaOfBlob');
    final shaOfTree = await _createTree(
        headers, owner, repo, shaOfParent, shaOfBlob, filename);
    debugPrint('### shaOfTree: $shaOfTree');
    final shaOfCommit = await _createCommit(
        headers, owner, repo, message, author, email, shaOfParent, shaOfTree);
    debugPrint('### shaOfCommit: $shaOfCommit');
    final ref = await _updateRef(headers, owner, repo, branch, shaOfCommit);
    debugPrint('### ref: $ref');
  }
}

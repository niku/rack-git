# -*- coding: utf-8 -*-
require "rack/lint"
require "rack/mock"
require "rack/git/file"

module Rack
  module Git
    describe File do

      def file(*args)
        Rack::Lint.new Rack::Git::File.new(*args)
      end

      subject { Rack::MockRequest.new(file(git_path)).get(access_path) }
      let(:git_path) { "spec/fixtures/default/dotgit" }

      describe "serve files" do

        context "when access file /README.md" do
          let(:access_path) { "/README.md" }
          it { is_expected.to be_ok }
          it { expect(subject.body).to match(/Directory Structure/) }
        end

        context "when access file using escaped name" do
          let(:access_path) { "/%E6%97%A5%E6%9C%AC%E8%AA%9E.txt" } # 日本語.txt
          it { is_expected.to be_ok }
          it {
            doc = subject.body
            doc.force_encoding("UTF-8")
            expect(doc).to match(/いろはにほへと/)
          }
        end

        context "when access file no exist" do
          let(:access_path) { "/no-exist-file" }
          it { is_expected.to be_not_found }
          it { expect(subject.body).to be_empty }
        end

      end

      describe "set Content-Length" do

        context "when access file /repository-root.txt" do
          let(:access_path) { "/repository-root.txt" }
          it { expect(subject.headers["Content-Length"]).to eq "36" }
        end

      end

      describe "set Content-Type" do

        context "when access text file" do
          let(:access_path) { "/repository-root.txt" }
          it { expect(subject.headers["Content-Type"]).to eq "text/plain" }
        end

        context "when access binary file" do
          let(:access_path) { "/pointing_hand_cursor.png" }
          it { expect(subject.headers["Content-Type"]).to eq "image/png" }
        end

      end

      describe "serve directories" do
        context "when access '/sub-dir'" do
          let(:access_path) { "/sub-dir/" }
          it { is_expected.to be_ok }
          it { expect(subject.body).to match(/sub-dir\.txt/) }
          it { expect(subject.body).to match(/nested-dir1\//) }
          it { expect(subject.body).to match(/nested-dir2\//) }
        end
      end

    end

  end
end

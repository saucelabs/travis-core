class Request
  class Approval
    attr_reader :request, :repository, :commit

    def initialize(request)
      @request = request
      @repository = request.repository
      @commit = request.commit
    end

    def accepted?
      commit.present? &&
        !repository.private? &&
        !blacklisted_repository? &&
        !skipped? &&
        !github_pages?
    end

    def approved?
      accepted? && request.config.present? && branch_approved?
    end

    def result
      approved? ? :accepted : :rejected
    end

    def message
      if !commit.present?
        'missing commit'
      elsif blacklisted_repository?
        'blacklisted repository'
      elsif skipped?
        'skipped through commit message'
      elsif github_pages?
        'github pages branch'
      elsif request.config.blank?
        'missing config'
      elsif !branch_approved?
        'branch not included or excluded'
      elsif repository.private?
        'private repository'
      end
    end

    private

      def skipped?
        commit.message.to_s =~ /\[ci(?: |:)([\w ]*)\]/i && $1.downcase == 'skip'
      end

      def github_pages?
        commit.ref =~ /gh[-_]pages/i
      end

      def blacklisted_repository?
        whitelist_rules.each do |rule|
          return false if repository.slug =~ rule
        end

        blacklist_rules.each do |rule|
          return true if repository.slug =~ rule
        end

        return false
      end
      
      def whitelist_rules
        @whitelist_rules ||= YAML.load_file('whiteblacklist.yml')['whitelist_rules'].map{|r| Regexp.new(r)} rescue []
      end

      def blacklist_rules
        @blacklist_rules ||= YAML.load_file('whiteblacklist.yml')['blacklist_rules'].map{|r| Regexp.new(r)} rescue []
      end

      def branch_approved?
        branches.included?(commit.branch) && !branches.excluded?(commit.branch)
      end

      def branches
        @branches ||= Branches.new(request)
      end
  end
end

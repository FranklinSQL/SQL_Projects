-- Step 1: Calculate company-level job statistics
WITH CompanyJobStats AS (
    SELECT 
        c.company_id,  -- Unique identifier for the company
        c.name AS company_name,  -- Name of the company
        COUNT(j.job_id) AS total_job_postings,  -- Total number of job postings for the company
        COALESCE(AVG(j.salary_year_avg), 0) AS avg_salary_year,  -- Average annual salary (default to 0 if no salaries exist)
        COALESCE(AVG(j.salary_hour_avg), 0) AS avg_salary_hour,  -- Average hourly salary (default to 0 if no salaries exist)
        -- Percentage of jobs offering health insurance
        ROUND(100.0 * SUM(CASE WHEN j.job_health_insurance THEN 1 ELSE 0 END) / NULLIF(COUNT(j.job_id), 0), 2) AS pct_with_health_insurance,
        -- Percentage of jobs not requiring a degree
        ROUND(100.0 * SUM(CASE WHEN j.job_no_degree_mention THEN 1 ELSE 0 END) / NULLIF(COUNT(j.job_id), 0), 2) AS pct_no_degree_required
    FROM 
        public.company_dim c  -- Base table for companies
    LEFT JOIN 
        public.job_postings_fact j ON c.company_id = j.company_id  -- Join to the job postings fact table
    WHERE 
        j.salary_year_avg IS NOT NULL  -- Filter out jobs with null salary values
    GROUP BY 
        c.company_id, c.name  -- Group by company to calculate metrics
),

-- Step 2: Rank companies by total number of job postings
RankedCompanies AS (
    SELECT 
        *,  -- Include all columns from CompanyJobStats
        RANK() OVER (ORDER BY total_job_postings DESC) AS company_rank  -- Rank companies based on job postings (highest to lowest)
    FROM 
        CompanyJobStats
),

-- Step 3: Aggregate all distinct skills associated with jobs for each company
CompanySkills AS (
    SELECT 
        c.company_id,  -- Unique identifier for the company
        COALESCE(STRING_AGG(DISTINCT s.skills, ', '), 'No skills listed') AS aggregated_skills  -- Concatenate unique skills into a single string
    FROM 
        public.company_dim c  -- Base table for companies
    LEFT JOIN 
        public.job_postings_fact j ON c.company_id = j.company_id  -- Join to the job postings fact table
    LEFT JOIN 
        public.skills_job_dim sj ON j.job_id = sj.job_id  -- Join to the skills-job linking table
    LEFT JOIN 
        public.skills_dim s ON sj.skill_id = s.skill_id  -- Join to the skills table
    WHERE 
        j.salary_year_avg IS NOT NULL  -- Only include jobs with non-null salaries
    GROUP BY 
        c.company_id  -- Group by company to aggregate skills
),

-- Step 4: Aggregate all distinct job titles for each company
CompanyJobTitles AS (
    SELECT 
        c.company_id,  -- Unique identifier for the company
        STRING_AGG(DISTINCT j.job_title_short, ', ') AS unique_job_titles  -- Concatenate unique job titles into a single string
    FROM 
        public.company_dim c  -- Base table for companies
    LEFT JOIN 
        public.job_postings_fact j ON c.company_id = j.company_id  -- Join to the job postings fact table
    WHERE 
        j.salary_year_avg IS NOT NULL  -- Only include jobs with non-null salaries
    GROUP BY 
        c.company_id  -- Group by company to aggregate job titles
)

-- Step 5: Combine all calculated data into a single result set
SELECT 
    rc.company_rank,  -- Rank of the company based on total job postings
    rc.company_name,  -- Name of the company
    rc.total_job_postings,  -- Total number of job postings
    rc.avg_salary_year,  -- Average annual salary
    rc.avg_salary_hour,  -- Average hourly salary
    rc.pct_with_health_insurance,  -- Percentage of jobs offering health insurance
    rc.pct_no_degree_required,  -- Percentage of jobs not requiring a degree
    cs.aggregated_skills,  -- Aggregated skills for the company
    cj.unique_job_titles  -- Aggregated job titles for the company
FROM 
    RankedCompanies rc  -- Base table containing ranked companies
LEFT JOIN 
    CompanySkills cs ON rc.company_id = cs.company_id  -- Join with skills data
LEFT JOIN 
    CompanyJobTitles cj ON rc.company_id = cj.company_id  -- Join with job titles data
ORDER BY 
    rc.company_rank;  -- Sort by company rank (highest to lowest)



